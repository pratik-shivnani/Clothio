import io
import logging

from PIL import Image
from rembg import remove

logger = logging.getLogger(__name__)


class BackgroundRemover:
    """Removes background from clothing images using rembg (U2Net)."""

    def remove(self, image_bytes: bytes) -> bytes:
        logger.info("Removing background from image (%d bytes)", len(image_bytes))
        result = remove(image_bytes)

        # Crop to content bounds (trim transparent borders)
        img = Image.open(io.BytesIO(result)).convert("RGBA")
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)

        output = io.BytesIO()
        img.save(output, format="PNG")
        return output.getvalue()
