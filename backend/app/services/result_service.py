from __future__ import annotations

from dataclasses import asdict

from app.core.responses import AppError
from app.repositories.in_memory import InMemoryStore
from app.services.ranking_service import RankingService


class ResultService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store
        self.ranking = RankingService(store)

    def get_session_results(self, session_id: str) -> dict:
        session = self.store.sessions.get(session_id)
        if not session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)

        trials = [asdict(t) for t in self.store.trials.values() if t.session_id == session_id]
        top_candidates = self.ranking.rank_session(session_id)

        return {
            "session": asdict(session),
            "top_candidates": top_candidates,
            "trial_count": len(trials),
            "trials": trials,
        }

    def export(self, session_id: str, fmt: str) -> dict:
        if session_id not in self.store.sessions:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        if fmt not in {"pdf", "csv", "json"}:
            raise AppError("VALIDATION_ERROR", "format must be one of: pdf,csv,json", status_code=422)
        return {
            "session_id": session_id,
            "format": fmt,
            "status": "queued" if fmt == "pdf" else "ready",
            "download_url": f"https://example.local/exports/{session_id}/result.{fmt}",
        }

