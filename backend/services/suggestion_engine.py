import logging
import math
from itertools import product

logger = logging.getLogger(__name__)

# Color wheel positions (hue approximations in degrees)
COLOR_HUES = {
    "red": 0, "orange": 30, "yellow": 60, "olive": 75,
    "green": 120, "teal": 180, "blue": 240, "navy": 230,
    "purple": 270, "pink": 330, "maroon": 345,
    "black": -1, "white": -1, "gray": -1, "beige": -1, "brown": 20,
}

TOP_TYPES = {"t-shirt", "shirt", "blouse", "sweater", "hoodie", "tank top",
             "polo shirt", "cardigan", "vest"}
BOTTOM_TYPES = {"pants", "jeans", "shorts", "skirt"}
LAYER_TYPES = {"jacket", "coat", "cardigan", "vest"}
FULL_BODY_TYPES = {"dress", "suit", "tracksuit"}


def _color_harmony_score(colors_a: list[str], colors_b: list[str]) -> float:
    """Score color harmony between two items (0-1)."""
    if not colors_a or not colors_b:
        return 0.5

    neutrals = {"black", "white", "gray", "beige"}

    scores = []
    for ca in colors_a:
        for cb in colors_b:
            # Neutrals go with everything
            if ca in neutrals or cb in neutrals:
                scores.append(0.9)
                continue

            # Same color family
            if ca == cb:
                scores.append(0.7)
                continue

            hue_a = COLOR_HUES.get(ca)
            hue_b = COLOR_HUES.get(cb)
            if hue_a is None or hue_b is None or hue_a == -1 or hue_b == -1:
                scores.append(0.5)
                continue

            diff = abs(hue_a - hue_b)
            if diff > 180:
                diff = 360 - diff

            # Complementary (opposite) colors
            if 150 <= diff <= 210:
                scores.append(0.85)
            # Analogous (neighbors)
            elif diff <= 40:
                scores.append(0.8)
            # Triadic
            elif 110 <= diff <= 130:
                scores.append(0.75)
            else:
                scores.append(0.4)

    return sum(scores) / len(scores) if scores else 0.5


def _occasion_score(item: dict, occasion: str) -> float:
    occasions = item.get("occasions", [])
    if not occasions:
        return 0.3
    if occasion.lower() in [o.lower() for o in occasions]:
        return 1.0
    return 0.2


def _season_score(item: dict, season: str | None) -> float:
    if not season:
        return 1.0
    seasons = item.get("seasons", [])
    if not seasons:
        return 0.5
    if season.lower() in [s.lower() for s in seasons]:
        return 1.0
    return 0.2


class SuggestionEngine:
    """Suggests outfits based on color harmony, occasion, and weather/season."""

    def suggest(
        self,
        wardrobe_items: list[dict],
        occasion: str | None = None,
        weather: dict | None = None,
    ) -> list[dict]:
        if not wardrobe_items:
            return []

        season = self._weather_to_season(weather) if weather else None

        tops = [i for i in wardrobe_items if i.get("type", "").lower() in TOP_TYPES]
        bottoms = [i for i in wardrobe_items if i.get("type", "").lower() in BOTTOM_TYPES]
        layers = [i for i in wardrobe_items if i.get("type", "").lower() in LAYER_TYPES]
        full_body = [i for i in wardrobe_items if i.get("type", "").lower() in FULL_BODY_TYPES]

        suggestions = []

        # Full body outfits
        for item in full_body:
            score = self._score_outfit([item], occasion, season)
            suggestions.append({
                "name": item.get("type", "Outfit"),
                "items": [self._item_summary(item)],
                "score": round(score, 2),
                "reason": self._reason([item], occasion, season),
            })

        # Top + Bottom combos
        for top, bottom in product(tops, bottoms):
            combo = [top, bottom]
            score = self._score_outfit(combo, occasion, season)
            if score >= 0.3:
                suggestions.append({
                    "name": f"{top.get('type', '')} + {bottom.get('type', '')}",
                    "items": [self._item_summary(i) for i in combo],
                    "score": round(score, 2),
                    "reason": self._reason(combo, occasion, season),
                })

        # Top + Bottom + Layer combos (top 3 layers)
        if season in ("autumn", "winter") or occasion in ("formal", "work"):
            for top, bottom in product(tops[:3], bottoms[:3]):
                for layer in layers[:2]:
                    combo = [top, bottom, layer]
                    score = self._score_outfit(combo, occasion, season)
                    if score >= 0.4:
                        suggestions.append({
                            "name": f"{layer.get('type', '')} + {top.get('type', '')} + {bottom.get('type', '')}",
                            "items": [self._item_summary(i) for i in combo],
                            "score": round(score, 2),
                            "reason": self._reason(combo, occasion, season),
                        })

        # Sort by score descending, limit to top 10
        suggestions.sort(key=lambda s: s["score"], reverse=True)
        return suggestions[:10]

    def _score_outfit(
        self,
        items: list[dict],
        occasion: str | None,
        season: str | None,
    ) -> float:
        if not items:
            return 0.0

        # Color harmony between all pairs
        color_scores = []
        for i in range(len(items)):
            for j in range(i + 1, len(items)):
                cs = _color_harmony_score(
                    items[i].get("colors", []),
                    items[j].get("colors", []),
                )
                color_scores.append(cs)
        avg_color = sum(color_scores) / len(color_scores) if color_scores else 0.5

        # Occasion match
        if occasion:
            occ_scores = [_occasion_score(i, occasion) for i in items]
            avg_occasion = sum(occ_scores) / len(occ_scores)
        else:
            avg_occasion = 0.7

        # Season match
        sea_scores = [_season_score(i, season) for i in items]
        avg_season = sum(sea_scores) / len(sea_scores)

        # Weighted average
        return avg_color * 0.4 + avg_occasion * 0.35 + avg_season * 0.25

    def _item_summary(self, item: dict) -> dict:
        return {
            "id": item.get("id"),
            "type": item.get("type"),
            "colors": item.get("colors", []),
            "image_path": item.get("image_path", ""),
        }

    def _reason(self, items: list[dict], occasion: str | None, season: str | None) -> str:
        parts = []
        all_colors = []
        for i in items:
            all_colors.extend(i.get("colors", []))

        unique_colors = list(dict.fromkeys(all_colors))
        if len(unique_colors) >= 2:
            parts.append(f"Colors: {', '.join(unique_colors[:3])}")

        if occasion:
            parts.append(f"For: {occasion}")
        if season:
            parts.append(f"Season: {season}")

        return " | ".join(parts) if parts else "General outfit suggestion"

    def _weather_to_season(self, weather: dict) -> str:
        temp = weather.get("temperature")
        if temp is None:
            return "spring"
        if temp < 10:
            return "winter"
        elif temp < 20:
            return "autumn"
        elif temp < 28:
            return "spring"
        else:
            return "summer"
