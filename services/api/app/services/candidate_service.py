from __future__ import annotations

from app.repositories.db_repositories import CandidateRepository


class CandidateService:
    def __init__(self, repository: CandidateRepository) -> None:
        self.repository = repository

    def list(
        self,
        species: str | None,
        country_code: str | None,
        language_code: str | None,
        q: str | None,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        return self.repository.list(species, country_code, language_code, q, page, page_size)

    def create(self, payload: dict) -> dict:
        return self.repository.create(payload)

    def update(self, candidate_id: str, payload: dict) -> dict:
        return self.repository.update(candidate_id, payload)

    def delete(self, candidate_id: str) -> None:
        self.repository.delete(candidate_id)
