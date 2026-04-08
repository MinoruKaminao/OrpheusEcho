from fastapi import APIRouter

from app.api.deps import trial_service
from app.core.responses import ok_response
from app.schemas.trial import TrialCreate, TrialFeatureCreate

router = APIRouter()


@router.post("/sessions/{session_id}/trials")
def create_trial(session_id: str, payload: TrialCreate) -> dict:
    trial = trial_service.create(session_id, payload.model_dump())
    return ok_response({"trial_id": trial["trial_id"], "status": "accepted_for_scoring"})


@router.post("/sessions/{session_id}/trials/{trial_id}/features")
def save_trial_features(session_id: str, trial_id: str, payload: TrialFeatureCreate) -> dict:
    _ = session_id
    features = trial_service.save_features(trial_id, payload.model_dump())
    return ok_response(features)

