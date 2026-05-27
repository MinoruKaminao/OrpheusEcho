from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.db_models import DbTTSProfile


class TTSRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_profiles(self) -> list[DbTTSProfile]:
        return self.db.query(DbTTSProfile).all()

    def get_profile(self, profile_id: str) -> DbTTSProfile | None:
        return self.db.query(DbTTSProfile).filter(DbTTSProfile.id == profile_id).first()

    def create_profile(self, payload: dict) -> DbTTSProfile:
        db_profile = DbTTSProfile(**payload)
        self.db.add(db_profile)
        self.db.commit()
        self.db.refresh(db_profile)
        return db_profile
