from fastapi import APIRouter, Depends, Query

from app.api.deps import get_result_service
from app.core.responses import ok_response
from app.services.result_service import ResultService

router = APIRouter()


@router.get("/sessions/{session_id}/results")
def get_results(
    session_id: str,
    service: ResultService = Depends(get_result_service)
) -> dict:
    return ok_response(service.get_session_results(session_id))


@router.get("/sessions/{session_id}/export")
def export_results(
    session_id: str,
    format: str = Query(...),
    service: ResultService = Depends(get_result_service)
) -> dict:
    return ok_response(service.export(session_id, format))
