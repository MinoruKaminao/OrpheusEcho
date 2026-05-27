from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.deps import get_model_service
from app.core.responses import ok_response
from app.services.model_service import ModelService

router = APIRouter()


class ExportRequest(BaseModel):
    session_ids: List[str]
    training_session_ids: List[str]
    anonymize: bool = True


class SyncRequest(BaseModel):
    export_job_id: str


@router.post("/training-data/export")
def export_training_data(
    payload: ExportRequest,
    service: ModelService = Depends(get_model_service)
) -> dict:
    res = service.export_data(
        session_ids=payload.session_ids,
        training_session_ids=payload.training_session_ids,
        anonymize=payload.anonymize
    )
    return ok_response(res)


@router.post("/training-data/sync")
def sync_training_data(
    payload: SyncRequest,
    service: ModelService = Depends(get_model_service)
) -> dict:
    res = service.start_sync_and_train(payload.export_job_id)
    return ok_response(res)


@router.get("/training-data/sync-status/{job_id}")
def get_sync_status(
    job_id: str,
    service: ModelService = Depends(get_model_service)
) -> dict:
    res = service.get_sync_job_status(job_id)
    return ok_response(res)
