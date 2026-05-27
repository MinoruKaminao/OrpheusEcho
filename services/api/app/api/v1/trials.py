from fastapi import APIRouter, Depends

from app.api.deps import get_trial_service
from app.core.responses import ok_response
from app.schemas.trial import TrialCreate, TrialFeatureCreate
from app.services.trial_service import TrialService

router = APIRouter()


@router.post("/sessions/{session_id}/trials")
def create_trial(
    session_id: str,
    payload: TrialCreate,
    service: TrialService = Depends(get_trial_service)
) -> dict:
    trial = service.create(session_id, payload.model_dump())
    return ok_response({"trial_id": trial["trial_id"], "status": "accepted_for_scoring"})


@router.post("/sessions/{session_id}/trials/{trial_id}/features")
def save_trial_features(
    session_id: str,
    trial_id: str,
    payload: TrialFeatureCreate,
    service: TrialService = Depends(get_trial_service)
) -> dict:
    _ = session_id
    features = service.save_features(trial_id, payload.model_dump())
    return ok_response(features)
