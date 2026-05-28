from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.responses import ok_response
from app.repositories.db_repositories import SessionRepository

router = APIRouter()


@router.get("/heatmap-points")
def get_heatmap_points(
    species: str | None = Query(None, description="Filter by species ('dog' or 'cat')"),
    db: Session = Depends(get_db)
):
    repo = SessionRepository(db)
    points = repo.list_heatmap_points(species=species)
    return ok_response({"points": points})
