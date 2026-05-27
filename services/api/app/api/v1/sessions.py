from fastapi import APIRouter, Depends

from app.api.deps import get_ranking_service, get_session_service
from app.core.responses import ok_response
from app.schemas.session import SessionCreate, SessionUpdate
from app.services.ranking_service import RankingService
from app.services.session_service import SessionService

router = APIRouter()


@router.post("/sessions")
def create_session(
    payload: SessionCreate,
    service: SessionService = Depends(get_session_service)
) -> dict:
    session = service.create(payload.model_dump())
    return ok_response({"session_id": session["session_id"], "status": session["status"]})


@router.get("/sessions/{session_id}")
def get_session(
    session_id: str,
    service: SessionService = Depends(get_session_service)
) -> dict:
    return ok_response(service.get(session_id))


@router.patch("/sessions/{session_id}")
def update_session(
    session_id: str,
    payload: SessionUpdate,
    service: SessionService = Depends(get_session_service)
) -> dict:
    return ok_response(service.update(session_id, payload.model_dump(exclude_none=True)))


@router.post("/sessions/{session_id}/close")
def close_session(
    session_id: str,
    service: SessionService = Depends(get_session_service)
) -> dict:
    session = service.close(session_id)
    return ok_response({"session_id": session["session_id"], "status": session["status"]})


@router.post("/sessions/{session_id}/rank")
def rank_session(
    session_id: str,
    service: RankingService = Depends(get_ranking_service)
) -> dict:
    top_candidates = service.rank_session(session_id)
    return ok_response({"top_candidates": top_candidates})


@router.post("/sessions/{session_id}/refine")
def refine_session(
    session_id: str,
    service: RankingService = Depends(get_ranking_service)
) -> dict:
    refined = service.refine(session_id)
    return ok_response({"refined_candidates": refined})
