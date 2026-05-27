from __future__ import annotations

from fastapi import APIRouter, Depends, Request

from app.api.deps import get_tts_service
from app.core.responses import ok_response
from app.schemas.country_dictionary import TTSProfileRead, TTSPreviewRequest, TTSPreviewResponse
from app.services.tts_service import TTSService

router = APIRouter()


@router.get("/tts/profiles")
def list_tts_profiles(
    service: TTSService = Depends(get_tts_service),
) -> dict:
    rows = service.get_profiles()
    data = [TTSProfileRead.from_orm(p).dict() for p in rows]
    return ok_response(data)


@router.post("/tts/preview")
def get_tts_preview(
    payload: TTSPreviewRequest,
    request: Request,
    service: TTSService = Depends(get_tts_service),
) -> dict:
    base_url = str(request.base_url)
    audio_url = service.generate_preview(
        text=payload.text,
        profile_id=payload.tts_profile_id,
        host_url=base_url,
    )
    res = TTSPreviewResponse(audio_url=audio_url, status="ready")
    return ok_response(res.dict())
