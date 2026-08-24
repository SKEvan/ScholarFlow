# ScholarFlow
Transform dozens of research papers into a structured literature review.

## Setup

1. Copy `.env.example` to `.env` in the repository root and fill in real keys.
2. Install backend dependencies in a virtualenv:
   ```bash
   python -m venv .venv
   .venv\Scripts\python.exe -m pip install -r backend/requirements.txt
   ```
3. Run the backend:
   ```bash
   .venv\Scripts\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 8765
   ```

## Deployment (Render)

The repo ships with `render.yaml` at the root. Render reads it when you create
a new Blueprint service. Secrets are **not** stored in git:

1. Push the repo to GitHub (`.env` is git-ignored).
2. In Render Dashboard → New → Blueprint, point at this repo.
3. Once the service is created, open **Environment** and add:
   - `SUPABASE_URL`
   - `SUPABASE_API_KEY` (or `SUPABASE_SERVICE_ROLE_KEY`)
   - `GEMINI_API_KEY`
   - `SEMANTIC_SCHOLAR_API_KEY` (optional)
4. Trigger a manual deploy. `python-dotenv` only reads `.env` from disk
   when the file exists, so Render's environment variables are used in
   production automatically.

See `.env.example` for the full list of supported variables.

## Pointing the Flutter app at a different backend

`lib/services/backend_api.dart` reads `BACKEND_URL` from `--dart-define`,
so each branch can ship its own endpoint without code changes:

```bash
# feature/backend-collaboration branch hits a preview Render service
flutter run -d windows --dart-define=BACKEND_URL=https://scholarflow-collaboration.onrender.com

# local uvicorn on the same machine
flutter run -d windows --dart-define=BACKEND_URL=http://127.0.0.1:8765

# default – production Render instance
flutter run -d windows
```

For runtime switches inside a running session (e.g. a "Use local backend"
button), call `BackendApi.useLocalBackend()` / `BackendApi.useProductionBackend()`
from any screen.
