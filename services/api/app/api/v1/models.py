from fastapi import APIRouter, Depends
from typing import List

from app.api.deps import get_model_service
from app.core.responses import ok_response
from app.schemas.model import (
    ModelUpdateCheckRequest,
    ModelUpdateCheckResponse,
    ModelApplyUpdateRequest,
    ModelApplyUpdateResponse,
    MLModelRead
)
from app.services.model_service import ModelService

router = APIRouter()


@router.get("/models/current")
def get_current_model(
    service: ModelService = Depends(get_model_service)
) -> dict:
    current = service.get_current_model()
    return ok_response(current)


@router.get("/models/versions")
def get_model_versions(
    service: ModelService = Depends(get_model_service)
) -> dict:
    versions = service.get_model_versions()
    return ok_response(versions)


@router.post("/models/check-update")
def check_model_update(
    payload: ModelUpdateCheckRequest,
    service: ModelService = Depends(get_model_service)
) -> dict:
    res = service.check_update(payload.current_version)
    return ok_response(res)


@router.post("/models/apply-update")
def apply_model_update(
    payload: ModelApplyUpdateRequest,
    service: ModelService = Depends(get_model_service)
) -> dict:
    res = service.apply_update(payload.version)
    return ok_response(res)
