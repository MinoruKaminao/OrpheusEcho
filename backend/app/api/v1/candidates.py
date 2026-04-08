from fastapi import APIRouter, Query

from app.api.deps import candidate_service
from app.core.responses import ok_response
from app.schemas.candidate import CandidateCreate, CandidateUpdate

router = APIRouter()


@router.get("/candidates")
def list_candidates(
    species: str | None = Query(default=None),
    country_code: str | None = Query(default=None),
    language_code: str | None = Query(default=None),
    q: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> dict:
    rows, total = candidate_service.list(species, country_code, language_code, q, page, page_size)
    return ok_response(rows, page=page, page_size=page_size, total=total)


@router.post("/candidates")
def create_candidate(payload: CandidateCreate) -> dict:
    return ok_response(candidate_service.create(payload.model_dump()))


@router.patch("/candidates/{candidate_id}")
def update_candidate(candidate_id: str, payload: CandidateUpdate) -> dict:
    return ok_response(candidate_service.update(candidate_id, payload.model_dump(exclude_none=True)))


@router.delete("/candidates/{candidate_id}")
def delete_candidate(candidate_id: str) -> dict:
    candidate_service.delete(candidate_id)
    return ok_response({"candidate_id": candidate_id, "status": "deactivated"})

