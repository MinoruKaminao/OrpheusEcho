from __future__ import annotations

from datetime import datetime
from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.models.db_models import DbJokeSession, DbJokeReactionLog, DbJokeNameProfile
from app.utils.ids import make_id


class JokeRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create_session(self, payload: dict) -> dict:
        session_id = make_id("jks")
        mapped_payload = {
            "id": session_id,
            "selected_country": payload.get("selected_country"),
            "selected_language": payload.get("selected_language"),
            "selected_age_band": payload.get("selected_age_band"),
            "tone_type": payload.get("tone_type"),
            "image_path": None,
            "created_at": datetime.utcnow(),
        }
        db_session = DbJokeSession(**mapped_payload)
        self.db.add(db_session)
        self.db.commit()
        self.db.refresh(db_session)
        return self._session_to_dict(db_session)

    def get_session(self, session_id: str) -> dict:
        db_session = self.db.query(DbJokeSession).filter(DbJokeSession.id == session_id).first()
        if not db_session:
            raise AppError("NOT_FOUND", "joke session not found", status_code=404)
        return self._session_to_dict(db_session)

    def update_session_image(self, session_id: str, image_path: str) -> dict:
        db_session = self.db.query(DbJokeSession).filter(DbJokeSession.id == session_id).first()
        if not db_session:
            raise AppError("NOT_FOUND", "joke session not found", status_code=404)
        db_session.image_path = image_path
        self.db.commit()
        self.db.refresh(db_session)
        return self._session_to_dict(db_session)

    def complete_session(self, session_id: str) -> dict:
        db_session = self.db.query(DbJokeSession).filter(DbJokeSession.id == session_id).first()
        if not db_session:
            raise AppError("NOT_FOUND", "joke session not found", status_code=404)
        db_session.completed_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_session)
        return self._session_to_dict(db_session)

    def list_candidates(self, country: str | None, language: str | None) -> list[dict]:
        query = self.db.query(DbJokeNameProfile).filter(DbJokeNameProfile.is_active == True)
        if country:
            query = query.filter(DbJokeNameProfile.country_code == country)
        if language:
            query = query.filter(DbJokeNameProfile.language_code == language)
        rows = query.all()
        return [self._candidate_to_dict(c) for c in rows]

    def get_candidate(self, candidate_id: str) -> dict:
        db_cand = self.db.query(DbJokeNameProfile).filter(DbJokeNameProfile.id == candidate_id).first()
        if not db_cand:
            raise AppError("NOT_FOUND", "joke candidate not found", status_code=404)
        return self._candidate_to_dict(db_cand)

    def create_reaction(self, session_id: str, payload: dict) -> dict:
        # 存在確認
        self.get_session(session_id)
        
        joke_profile_id = payload.get("joke_profile_id")
        self.get_candidate(joke_profile_id)

        reaction_id = make_id("jkr")
        smile = payload.get("smile_score", 0.0)
        laugh = payload.get("laugh_score", 0.0)
        manual = payload.get("manual_reaction")

        # 複合スコアの簡易 Heuristics 計算: 手動評価を優先しつつ表情スコアをブレンド
        # reaction_yes = 1.0, reaction_meh = 0.5, reaction_no = 0.0
        manual_val = 0.0
        if manual == "reaction_yes":
            manual_val = 1.0
        elif manual == "reaction_meh":
            manual_val = 0.5

        # 手動が入力されている場合は手動評価60% + 表情40% (笑顔30% + 笑い声10%)
        # 手動がない場合は表情のみ
        if manual is not None:
            composite = (manual_val * 0.6) + (smile * 0.3) + (laugh * 0.1)
        else:
            composite = (smile * 0.7) + (laugh * 0.3)

        mapped_payload = {
            "id": reaction_id,
            "joke_session_id": session_id,
            "joke_profile_id": joke_profile_id,
            "smile_score": smile,
            "laugh_score": laugh,
            "manual_reaction": manual,
            "composite_score": min(max(composite, 0.0), 1.0),
            "created_at": datetime.utcnow(),
        }
        db_reaction = DbJokeReactionLog(**mapped_payload)
        self.db.add(db_reaction)
        self.db.commit()
        self.db.refresh(db_reaction)
        return self._reaction_to_dict(db_reaction)

    def list_reactions(self, session_id: str) -> list[dict]:
        rows = self.db.query(DbJokeReactionLog).filter(DbJokeReactionLog.joke_session_id == session_id).all()
        return [self._reaction_to_dict(r) for r in rows]

    def _session_to_dict(self, db_session: DbJokeSession) -> dict:
        return {
            "joke_session_id": db_session.id,
            "selected_country": db_session.selected_country,
            "selected_language": db_session.selected_language,
            "selected_age_band": db_session.selected_age_band,
            "tone_type": db_session.tone_type,
            "image_path": db_session.image_path,
            "created_at": db_session.created_at.isoformat() + "Z" if db_session.created_at else None,
            "completed_at": db_session.completed_at.isoformat() + "Z" if db_session.completed_at else None,
        }

    def _candidate_to_dict(self, db_cand: DbJokeNameProfile) -> dict:
        return {
            "joke_profile_id": db_cand.id,
            "name": db_cand.name,
            "type": db_cand.type,
            "language_code": db_cand.language_code,
            "country_code": db_cand.country_code,
            "is_active": db_cand.is_active,
        }

    def _reaction_to_dict(self, db_reaction: DbJokeReactionLog) -> dict:
        return {
            "joke_reaction_id": db_reaction.id,
            "joke_session_id": db_reaction.joke_session_id,
            "joke_profile_id": db_reaction.joke_profile_id,
            "smile_score": float(db_reaction.smile_score),
            "laugh_score": float(db_reaction.laugh_score),
            "manual_reaction": db_reaction.manual_reaction,
            "composite_score": float(db_reaction.composite_score),
            "created_at": db_reaction.created_at.isoformat() + "Z" if db_reaction.created_at else None,
        }
