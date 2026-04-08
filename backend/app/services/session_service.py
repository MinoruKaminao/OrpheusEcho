from __future__ import annotations

from dataclasses import asdict
from datetime import datetime, timezone

from app.core.responses import AppError
from app.models.entities import Session
from app.repositories.in_memory import InMemoryStore
from app.utils.ids import make_id


class SessionService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store

    def create(self, payload: dict) -> dict:
        session = Session(session_id=make_id("ses"), **payload)
        self.store.sessions[session.session_id] = session
        return asdict(session)

    def get(self, session_id: str) -> dict:
        session = self.store.sessions.get(session_id)
        if not session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        return asdict(session)

    def update(self, session_id: str, payload: dict) -> dict:
        session = self.store.sessions.get(session_id)
        if not session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        for k, v in payload.items():
            setattr(session, k, v)
        session.updated_at = datetime.now(timezone.utc)
        return asdict(session)

    def close(self, session_id: str) -> dict:
        session = self.store.sessions.get(session_id)
        if not session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        session.status = "closed"
        session.updated_at = datetime.now(timezone.utc)
        return asdict(session)

