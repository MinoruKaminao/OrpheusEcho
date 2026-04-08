from fastapi import APIRouter

from app.core.responses import ok_response

router = APIRouter()


@router.get("/health")
def health() -> dict:
    return ok_response({"status": "ok"})

