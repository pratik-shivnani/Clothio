# Clothio

Virtual wardrobe & try-on app — photograph clothes, auto-crop them, virtually try them on, and get outfit suggestions.

## Features

- **Wardrobe Management** — Capture or import photos of clothes; background is auto-removed and the item is classified by type, color, and style
- **Virtual Try-On** — Take a body photo and preview how clothes look on you
- **Outfit Suggestions** — Get AI-powered outfit recommendations based on color harmony, occasion, and weather
- **Profile** — Body photo management, wardrobe stats, backend status

## Tech Stack

| Layer | Tech |
|-------|------|
| Mobile App | Flutter 3.x, Riverpod, GoRouter, Drift |
| Backend | Python 3.11, FastAPI |
| Background Removal | rembg (U2Net) |
| Classification | CLIP (zero-shot) + OpenCV |
| Virtual Try-On | Overlay (placeholder) — IDM-VTON planned |
| Suggestions | Color theory + occasion + weather scoring |

## Setup

### Flutter App

```bash
fvm use stable
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
fvm flutter run
```

### Python Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

The backend runs on `http://localhost:8000`. The Flutter app connects to it automatically.
