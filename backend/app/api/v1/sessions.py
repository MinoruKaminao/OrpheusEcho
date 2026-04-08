from fastapi import APIRouter

from app.api.deps import ranking_service, session_service
from app.core.responses import ok_response
from app.schemas.session import SessionCreate, SessionUpdate

router = APIRouter()


@router.post("/sessions")
def create_session(payload: SessionCreate) -> dict:
    session = session_service.create(payload.model_dump())
    return ok_response({"session_id": session["session_id"], "status": session["status"]})


@router.get("/sessions/{session_id}")
def get_session(session_id: str) -> dict:
    return ok_response(session_service.get(session_id))


@router.patch("/sessions/{session_id}")
def update_session(session_id: str, payload: SessionUpdate) -> dict:
    return ok_response(session_service.update(session_id, payload.model_dump(exclude_none=True)))


@router.post("/sessions/{session_id}/close")
def close_session(session_id: str) -> dict:
    session = session_service.close(session_id)
    return ok_response({"session_id": session["session_id"], "status": session["status"]})


@router.post("/sessions/{session_id}/rank")
def rank_session(session_id: str) -> dict:
    top_candidates = ranking_service.rank_session(session_id)
    return ok_response({"top_candidates": top_candidates})


@router.post("/sessions/{session_id}/refine")
def refine_session(session_id: str) -> dict:
    refined = ranking_service.refine(session_id)
    return ok_response({"refined_candidates": refined})

