from __future__ import annotations

from fastapi import APIRouter, Depends, File, UploadFile

from app.api.deps import get_joke_service
from app.core.responses import ok_response
from app.schemas.joke_schemas import JokeSessionCreate, JokeReactionCreate
from app.services.joke_service import JokeService

router = APIRouter()


@router.post("/joke-sessions")
def create_joke_session(
    payload: JokeSessionCreate,
    service: JokeService = Depends(get_joke_service)
) -> dict:
    session = service.create_session(payload.model_dump())
    return ok_response(session)


@router.post("/joke-sessions/{joke_session_id}/image")
def upload_joke_image(
    joke_session_id: str,
    file: UploadFile = File(...),
    service: JokeService = Depends(get_joke_service)
) -> dict:
    content = file.file.read()
    res = service.upload_image(joke_session_id, file.filename, content)
    return ok_response(res)


@router.post("/joke-sessions/{joke_session_id}/generate-candidates")
def generate_joke_candidates(
    joke_session_id: str,
    service: JokeService = Depends(get_joke_service)
) -> dict:
    candidates = service.generate_candidates(joke_session_id)
    return ok_response({"candidates": candidates})


@router.post("/joke-sessions/{joke_session_id}/reactions")
def create_joke_reaction(
    joke_session_id: str,
    payload: JokeReactionCreate,
    service: JokeService = Depends(get_joke_service)
) -> dict:
    res = service.create_reaction(joke_session_id, payload.model_dump())
    return ok_response(res)


@router.get("/joke-sessions/{joke_session_id}/results")
def get_joke_results(
    joke_session_id: str,
    service: JokeService = Depends(get_joke_service)
) -> dict:
    res = service.get_results(joke_session_id)
    return ok_response(res)
