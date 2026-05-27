from fastapi import APIRouter, Depends

from app.api.deps import get_training_service
from app.core.responses import ok_response
from app.schemas.training import TrainingSessionCreate, TrainingTrialCreate
from app.services.training_service import TrainingService

router = APIRouter()


@router.post("/training-sessions")
def create_session(
    payload: TrainingSessionCreate,
    service: TrainingService = Depends(get_training_service)
) -> dict:
    session = service.create_session(payload.model_dump())
    return ok_response(session)


@router.post("/training-sessions/{training_session_id}/trials")
def add_trial(
    training_session_id: str,
    payload: TrainingTrialCreate,
    service: TrainingService = Depends(get_training_service)
) -> dict:
    trial = service.add_trial(training_session_id, payload.model_dump())
    return ok_response(trial)


@router.post("/training-sessions/{training_session_id}/complete")
def complete_session(
    training_session_id: str,
    service: TrainingService = Depends(get_training_service)
) -> dict:
    session = service.complete_session(training_session_id)
    return ok_response(session)
