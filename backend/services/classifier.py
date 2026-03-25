import io
import logging
from collections import Counter

import cv2
import numpy as np
from PIL import Image
from sklearn.cluster import KMeans

logger = logging.getLogger(__name__)

# CLIP-based classification will be loaded lazily
_clip_model = None
_clip_processor = None

CLOTHING_TYPES = [
    "t-shirt", "shirt", "blouse", "sweater", "hoodie", "jacket", "coat",
    "dress", "skirt", "pants", "jeans", "shorts", "suit", "tank top",
    "cardigan", "vest", "polo shirt", "tracksuit", "swimwear",
    "scarf", "hat", "belt", "shoes", "sneakers", "boots", "sandals",
]

STYLE_LABELS = ["casual", "formal", "sporty", "elegant", "streetwear", "bohemian"]
SEASON_LABELS = ["spring", "summer", "autumn", "winter"]
OCCASION_LABELS = ["casual", "formal", "party", "date night", "work", "gym", "outdoor"]

# Color name mapping (approximate)
COLOR_NAMES = {
    (0, 0, 0): "black",
    (255, 255, 255): "white",
    (128, 128, 128): "gray",
    (255, 0, 0): "red",
    (0, 255, 0): "green",
    (0, 0, 255): "blue",
    (255, 255, 0): "yellow",
    (255, 165, 0): "orange",
    (128, 0, 128): "purple",
    (255, 192, 203): "pink",
    (165, 42, 42): "brown",
    (0, 128, 128): "teal",
    (0, 0, 128): "navy",
    (245, 245, 220): "beige",
    (128, 0, 0): "maroon",
    (128, 128, 0): "olive",
}


def _closest_color_name(rgb: tuple[int, int, int]) -> str:
    min_dist = float("inf")
    name = "unknown"
    for ref_rgb, ref_name in COLOR_NAMES.items():
        dist = sum((a - b) ** 2 for a, b in zip(rgb, ref_rgb))
        if dist < min_dist:
            min_dist = dist
            name = ref_name
    return name


def _extract_dominant_colors(image_bytes: bytes, n_colors: int = 3) -> list[str]:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        return []

    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (100, 100))
    pixels = img.reshape(-1, 3).astype(np.float32)

    # Filter out near-black and near-white (likely background)
    mask = (pixels.sum(axis=1) > 30) & (pixels.sum(axis=1) < 700)
    pixels = pixels[mask]

    if len(pixels) < n_colors:
        return ["unknown"]

    kmeans = KMeans(n_clusters=n_colors, n_init=10, random_state=42)
    kmeans.fit(pixels)

    colors = []
    for center in kmeans.cluster_centers_:
        rgb = tuple(int(c) for c in center)
        colors.append(_closest_color_name(rgb))

    # Deduplicate while preserving order
    seen = set()
    unique = []
    for c in colors:
        if c not in seen:
            seen.add(c)
            unique.append(c)

    return unique


def _get_clip_model():
    global _clip_model, _clip_processor
    if _clip_model is None:
        from transformers import CLIPProcessor, CLIPModel
        logger.info("Loading CLIP model...")
        _clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
        _clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
        logger.info("CLIP model loaded")
    return _clip_model, _clip_processor


def _classify_with_clip(image_bytes: bytes, labels: list[str]) -> str:
    import torch
    model, processor = _get_clip_model()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    inputs = processor(
        text=[f"a photo of {label}" for label in labels],
        images=image,
        return_tensors="pt",
        padding=True,
    )

    with torch.no_grad():
        outputs = model(**inputs)

    logits = outputs.logits_per_image[0]
    probs = logits.softmax(dim=0)
    best_idx = probs.argmax().item()
    return labels[best_idx]


class ClothingClassifier:
    """Classifies clothing type, style, colors, seasons using CLIP + OpenCV."""

    def classify(self, image_bytes: bytes) -> dict:
        logger.info("Classifying clothing image (%d bytes)", len(image_bytes))

        clothing_type = _classify_with_clip(image_bytes, CLOTHING_TYPES)
        style = _classify_with_clip(image_bytes, STYLE_LABELS)
        colors = _extract_dominant_colors(image_bytes)

        # Determine seasons based on type + style
        seasons = self._infer_seasons(clothing_type, style)
        occasions = self._infer_occasions(clothing_type, style)

        return {
            "type": clothing_type,
            "sub_type": style,
            "colors": colors,
            "seasons": seasons,
            "occasions": occasions,
            "tags": [clothing_type, style] + colors,
        }

    def _infer_seasons(self, clothing_type: str, style: str) -> list[str]:
        warm = {"coat", "jacket", "sweater", "hoodie", "cardigan", "boots", "scarf"}
        cool = {"t-shirt", "tank top", "shorts", "sandals", "swimwear"}

        seasons = []
        if clothing_type in warm:
            seasons = ["autumn", "winter"]
        elif clothing_type in cool:
            seasons = ["spring", "summer"]
        else:
            seasons = ["spring", "summer", "autumn", "winter"]
        return seasons

    def _infer_occasions(self, clothing_type: str, style: str) -> list[str]:
        formal_types = {"suit", "dress", "blouse", "coat"}
        sporty_types = {"tracksuit", "sneakers", "shorts"}

        occasions = ["casual"]
        if clothing_type in formal_types or style == "formal":
            occasions = ["formal", "work", "date night"]
        if clothing_type in formal_types or style == "elegant":
            occasions.append("party")
        if clothing_type in sporty_types or style == "sporty":
            occasions = ["gym", "outdoor", "casual"]
        return list(set(occasions))
