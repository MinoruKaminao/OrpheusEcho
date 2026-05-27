from __future__ import annotations

from app.repositories.db_repositories import SessionRepository


class SessionService:
    def __init__(self, repository: SessionRepository) -> None:
        self.repository = repository

    def create(self, payload: dict) -> dict:
        return self.repository.create(payload)

    def get(self, session_id: str) -> dict:
        return self.repository.get(session_id)

    def update(self, session_id: str, payload: dict) -> dict:
        return self.repository.update(session_id, payload)

    def close(self, session_id: str) -> dict:
        return self.repository.close(session_id)
