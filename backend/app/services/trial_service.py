from __future__ import annotations

from dataclasses import asdict

from app.core.responses import AppError
from app.models.entities import ReactionFeatures, Trial
from app.repositories.in_memory import InMemoryStore
from app.utils.ids import make_id


class TrialService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store

    def create(self, session_id: str, payload: dict) -> dict:
        if session_id not in self.store.sessions:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        if payload["candidate_id"] not in self.store.candidates:
            raise AppError("NOT_FOUND", "candidate not found", status_code=404)
        trial = Trial(trial_id=make_id("trl"), session_id=session_id, **payload)
        self.store.trials[trial.trial_id] = trial
        return asdict(trial)

    def save_features(self, trial_id: str, payload: dict) -> dict:
        if trial_id not in self.store.trials:
            raise AppError("NOT_FOUND", "trial not found", status_code=404)
        features = ReactionFeatures(trial_id=trial_id, **payload)
        self.store.features[trial_id] = features
        return asdict(features)

