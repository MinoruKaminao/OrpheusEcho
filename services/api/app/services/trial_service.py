from __future__ import annotations

from app.repositories.db_repositories import TrialRepository


class TrialService:
    def __init__(self, repository: TrialRepository) -> None:
        self.repository = repository

    def create(self, session_id: str, payload: dict) -> dict:
        return self.repository.create(session_id, payload)

    def save_features(self, trial_id: str, payload: dict) -> dict:
        return self.repository.save_features(trial_id, payload)
