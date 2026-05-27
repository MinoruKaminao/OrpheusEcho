from __future__ import annotations

from dataclasses import asdict

from app.core.responses import AppError
from app.models.entities import Candidate
from app.repositories.in_memory import InMemoryStore
from app.utils.ids import make_id


class CandidateService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store

    def list(
        self,
        species: str | None,
        country_code: str | None,
        language_code: str | None,
        q: str | None,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        rows = [c for c in self.store.candidates.values() if c.active]
        if species:
            rows = [c for c in rows if c.species == species]
        if country_code:
            rows = [c for c in rows if c.country_code == country_code]
        if language_code:
            rows = [c for c in rows if c.language_code == language_code]
        if q:
            rows = [c for c in rows if q in c.name]
        total = len(rows)
        start = (page - 1) * page_size
        end = start + page_size
        return [asdict(c) for c in rows[start:end]], total

    def create(self, payload: dict) -> dict:
        candidate = Candidate(candidate_id=make_id("cand"), **payload)
        self.store.candidates[candidate.candidate_id] = candidate
        return asdict(candidate)

    def update(self, candidate_id: str, payload: dict) -> dict:
        candidate = self.store.candidates.get(candidate_id)
        if not candidate:
            raise AppError("NOT_FOUND", "candidate not found", status_code=404)
        for k, v in payload.items():
            setattr(candidate, k, v)
        return asdict(candidate)

    def delete(self, candidate_id: str) -> None:
        candidate = self.store.candidates.get(candidate_id)
        if not candidate:
            raise AppError("NOT_FOUND", "candidate not found", status_code=404)
        candidate.active = False
