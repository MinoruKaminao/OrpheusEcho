from __future__ import annotations

from datetime import datetime
from sqlalchemy.orm import Session
from app.core.responses import AppError
from app.models.db_models import DbKnownAnimal, DbTrainingSession, DbTrainingTrial
from app.utils.ids import make_id


class TrainingRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create_session(self, payload: dict) -> dict:
        animal_id = payload.get("known_animal_id")
        animal = self.db.query(DbKnownAnimal).filter(DbKnownAnimal.id == animal_id).first()
        if not animal:
            raise AppError("NOT_FOUND", "Known animal not found", status_code=404)

        session_id = payload.get("id") or make_id("trs")
        
        # Check idempotency
        exists = self.db.query(DbTrainingSession).filter(DbTrainingSession.id == session_id).first()
        if exists:
            return self._session_to_dict(exists)

        db_session = DbTrainingSession(
            id=session_id,
            known_animal_id=animal_id,
            speaker_type=payload.get("speaker_type"),
            environment_type=payload.get("environment_type"),
            purpose=payload.get("purpose"),
            status="created",
            created_at=datetime.utcnow()
        )
        self.db.add(db_session)
        self.db.commit()
        self.db.refresh(db_session)
        return self._session_to_dict(db_session)

    def add_trial(self, session_id: str, payload: dict) -> dict:
        session = self.db.query(DbTrainingSession).filter(DbTrainingSession.id == session_id).first()
        if not session:
            raise AppError("NOT_FOUND", "Training session not found", status_code=404)

        trial_id = payload.get("id") or make_id("trt")
        
        # Check idempotency
        exists = self.db.query(DbTrainingTrial).filter(DbTrainingTrial.id == trial_id).first()
        if exists:
            return self._trial_to_dict(exists)

        db_trial = DbTrainingTrial(
            id=trial_id,
            training_session_id=session_id,
            called_name=payload.get("called_name"),
            is_true_name=payload.get("is_true_name"),
            is_alias=payload.get("is_alias"),
            modulation_type=payload.get("modulation_type"),
            playback_source=payload.get("playback_source"),
            manual_reaction=payload.get("manual_reaction"),
            created_at=datetime.utcnow()
        )
        self.db.add(db_trial)
        self.db.commit()
        self.db.refresh(db_trial)
        return self._trial_to_dict(db_trial)

    def complete_session(self, session_id: str) -> dict:
        session = self.db.query(DbTrainingSession).filter(DbTrainingSession.id == session_id).first()
        if not session:
            raise AppError("NOT_FOUND", "Training session not found", status_code=404)

        session.status = "completed"
        session.completed_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(session)
        return self._session_to_dict(session)

    def _session_to_dict(self, db_session: DbTrainingSession) -> dict:
        return {
            "id": db_session.id,
            "known_animal_id": db_session.known_animal_id,
            "speaker_type": db_session.speaker_type,
            "environment_type": db_session.environment_type,
            "purpose": db_session.purpose,
            "status": db_session.status,
            "created_at": db_session.created_at.isoformat() + "Z" if db_session.created_at else None,
            "completed_at": db_session.completed_at.isoformat() + "Z" if db_session.completed_at else None
        }

    def _trial_to_dict(self, db_trial: DbTrainingTrial) -> dict:
        return {
            "id": db_trial.id,
            "training_session_id": db_trial.training_session_id,
            "called_name": db_trial.called_name,
            "is_true_name": db_trial.is_true_name,
            "is_alias": db_trial.is_alias,
            "modulation_type": db_trial.modulation_type,
            "playback_source": db_trial.playback_source,
            "manual_reaction": db_trial.manual_reaction,
            "created_at": db_trial.created_at.isoformat() + "Z" if db_trial.created_at else None
        }
