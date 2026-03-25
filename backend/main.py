import io
import json
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import Response, JSONResponse

from services.background_remover import BackgroundRemover
from services.classifier import ClothingClassifier
from services.suggestion_engine import SuggestionEngine

logger = logging.getLogger(__name__)

bg_remover: BackgroundRemover | None = None
classifier: ClothingClassifier | None = None
suggestion_engine: SuggestionEngine | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global bg_remover, classifier, suggestion_engine
    logger.info("Loading ML models...")
    bg_remover = BackgroundRemover()
    classifier = ClothingClassifier()
    suggestion_engine = SuggestionEngine()
    logger.info("Models loaded successfully")
    yield
    logger.info("Shutting down...")


app = FastAPI(title="Clothio Backend", version="0.1.0", lifespan=lifespan)


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.post("/remove-bg")
async def remove_background(file: UploadFile = File(...)):
    image_bytes = await file.read()
    result_bytes = bg_remover.remove(image_bytes)
    return Response(content=result_bytes, media_type="image/png")


@app.post("/classify")
async def classify_clothing(file: UploadFile = File(...)):
    image_bytes = await file.read()
    result = classifier.classify(image_bytes)
    return JSONResponse(content=result)


@app.post("/try-on")
async def try_on(
    body: UploadFile = File(...),
    clothing: UploadFile = File(...),
):
    body_bytes = await body.read()
    clothing_bytes = await clothing.read()

    # Placeholder: overlay clothing on body
    # Full implementation requires IDM-VTON/OOTDiffusion (Phase 3)
    from services.tryon_engine import TryOnEngine
    engine = TryOnEngine()
    result_bytes = engine.try_on(body_bytes, clothing_bytes)
    return Response(content=result_bytes, media_type="image/png")


@app.post("/suggest")
async def suggest_outfits(request: dict):
    wardrobe = request.get("wardrobe", [])
    occasion = request.get("occasion")
    weather = request.get("weather")

    suggestions = suggestion_engine.suggest(
        wardrobe_items=wardrobe,
        occasion=occasion,
        weather=weather,
    )
    return JSONResponse(content=suggestions)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
