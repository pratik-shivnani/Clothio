import io
import logging

import cv2
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)


class TryOnEngine:
    """Virtual try-on engine.

    Phase 3 placeholder: Currently does a basic overlay composite.
    Full implementation will use IDM-VTON or OOTDiffusion for realistic try-on.
    """

    def try_on(self, body_bytes: bytes, clothing_bytes: bytes) -> bytes:
        logger.info("Running try-on (basic overlay mode)")

        # Load images
        body_img = Image.open(io.BytesIO(body_bytes)).convert("RGBA")
        clothing_img = Image.open(io.BytesIO(clothing_bytes)).convert("RGBA")

        # Resize clothing to fit roughly on the body torso area
        body_w, body_h = body_img.size
        clothing_w = int(body_w * 0.6)
        clothing_h = int(clothing_w * clothing_img.height / clothing_img.width)
        clothing_resized = clothing_img.resize(
            (clothing_w, clothing_h),
            Image.Resampling.LANCZOS,
        )

        # Position clothing on upper body (roughly center-top third)
        x_offset = (body_w - clothing_w) // 2
        y_offset = int(body_h * 0.2)

        # Composite
        result = body_img.copy()
        result.paste(clothing_resized, (x_offset, y_offset), clothing_resized)

        # Convert back to bytes
        output = io.BytesIO()
        result.save(output, format="PNG")
        return output.getvalue()
