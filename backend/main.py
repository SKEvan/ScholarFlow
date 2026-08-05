from datetime import datetime, timezone

from fastapi import FastAPI


app = FastAPI(title="ScholarFlow Backend", version="0.1.0")


@app.get("/")
def root() -> dict[str, str]:
    return {
        "message": "ScholarFlow backend is running.",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "message": "Backend is healthy.",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)