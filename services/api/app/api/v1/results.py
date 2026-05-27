from fastapi import APIRouter, Query

from app.api.deps import result_service
from app.core.responses import ok_response

router = APIRouter()


@router.get("/sessions/{session_id}/results")
def get_results(session_id: str) -> dict:
    return ok_response(result_service.get_session_results(session_id))


@router.get("/sessions/{session_id}/export")
def export_results(session_id: str, format: str = Query(...)) -> dict:
    return ok_response(result_service.export(session_id, format))
