from __future__ import annotations

from app.repositories.training_repository import TrainingRepository


class TrainingService:
    def __init__(self, repository: TrainingRepository) -> None:
        self.repository = repository

    def create_session(self, payload: dict) -> dict:
        return self.repository.create_session(payload)

    def add_trial(self, session_id: str, payload: dict) -> dict:
        return self.repository.add_trial(session_id, payload)

    def complete_session(self, session_id: str) -> dict:
        return self.repository.complete_session(session_id)
