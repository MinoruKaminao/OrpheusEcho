from __future__ import annotations

from dataclasses import asdict
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.models.db_models import DbCandidate, DbReactionFeatures, DbSession, DbTrial
from app.models.entities import Candidate, ReactionFeatures, Session as EntSession, Trial
from app.utils.ids import make_id


class SessionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, payload: dict) -> dict:
        session_id = make_id("ses")
        
        # フィールドのマッピング
        extra_notes = []
        if payload.get("temp_animal_id"):
            extra_notes.append(f"TempID: {payload['temp_animal_id']}")
        if payload.get("coat_color"):
            extra_notes.append(f"Coat: {payload['coat_color']}")
        if payload.get("age_hint"):
            extra_notes.append(f"Age: {payload['age_hint']}")
        if payload.get("notes"):
            extra_notes.append(payload["notes"])
            
        mapped_payload = {
            "id": session_id,
            "species": payload.get("species"),
            "status": "created",
            "country": payload.get("country_code"),
            "language": payload.get("language_code"),
            "location_text": payload.get("location_text"),
            "latitude": payload.get("latitude"),
            "longitude": payload.get("longitude"),
            "animal_notes": " | ".join(extra_notes) if extra_notes else None,
            "sync_status": "completed",
        }
        
        db_session = DbSession(**mapped_payload)
        self.db.add(db_session)
        self.db.commit()
        self.db.refresh(db_session)
        return self._to_dict(db_session)

    def get(self, session_id: str) -> dict:
        db_session = self.db.query(DbSession).filter(DbSession.id == session_id).first()
        if not db_session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        return self._to_dict(db_session)

    def update(self, session_id: str, payload: dict) -> dict:
        db_session = self.db.query(DbSession).filter(DbSession.id == session_id).first()
        if not db_session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        
        # マッピングしながら更新
        if "species" in payload:
            db_session.species = payload["species"]
        if "country_code" in payload:
            db_session.country = payload["country_code"]
        if "language_code" in payload:
            db_session.language = payload["language_code"]
        if "location_text" in payload:
            db_session.location_text = payload["location_text"]
        if "latitude" in payload:
            db_session.latitude = payload["latitude"]
        if "longitude" in payload:
            db_session.longitude = payload["longitude"]
        if "status" in payload:
            db_session.status = payload["status"]
            
        # メモの再構築
        extra_notes = []
        temp_id = payload.get("temp_animal_id") or (db_session.animal_notes.split(" | ")[0].replace("TempID: ", "") if db_session.animal_notes and "TempID: " in db_session.animal_notes else None)
        coat = payload.get("coat_color") or (db_session.animal_notes.split(" | ")[1].replace("Coat: ", "") if db_session.animal_notes and "Coat: " in db_session.animal_notes else None)
        age = payload.get("age_hint") or (db_session.animal_notes.split(" | ")[2].replace("Age: ", "") if db_session.animal_notes and "Age: " in db_session.animal_notes else None)
        notes = payload.get("notes") or (db_session.animal_notes.split(" | ")[-1] if db_session.animal_notes else None)
        
        if temp_id:
            extra_notes.append(f"TempID: {temp_id}")
        if coat:
            extra_notes.append(f"Coat: {coat}")
        if age:
            extra_notes.append(f"Age: {age}")
        if notes and notes not in {f"TempID: {temp_id}", f"Coat: {coat}", f"Age: {age}"}:
            extra_notes.append(notes)
            
        db_session.animal_notes = " | ".join(extra_notes) if extra_notes else None
        
        db_session.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_session)
        return self._to_dict(db_session)

    def close(self, session_id: str) -> dict:
        db_session = self.db.query(DbSession).filter(DbSession.id == session_id).first()
        if not db_session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        db_session.status = "closed"
        db_session.completed_at = datetime.utcnow()
        db_session.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_session)
        return self._to_dict(db_session)

    def _to_dict(self, db_session: DbSession) -> dict:
        temp_id = None
        coat = None
        age = None
        notes = db_session.animal_notes
        latitude = float(db_session.latitude) if db_session.latitude is not None else None
        longitude = float(db_session.longitude) if db_session.longitude is not None else None

        if db_session.animal_notes:
            parts = db_session.animal_notes.split(" | ")
            notes_parts = []
            for part in parts:
                if part.startswith("TempID: "):
                    temp_id = part.replace("TempID: ", "")
                elif part.startswith("Coat: "):
                    coat = part.replace("Coat: ", "")
                elif part.startswith("Age: "):
                    age = part.replace("Age: ", "")
                else:
                    notes_parts.append(part)
            notes = " | ".join(notes_parts) if notes_parts else None

        return {
            "session_id": db_session.id,
            "species": db_session.species,
            "temp_animal_id": temp_id,
            "location_text": db_session.location_text,
            "latitude": latitude,
            "longitude": longitude,
            "coat_color": coat,
            "age_hint": age,
            "country_code": db_session.country,
            "language_code": db_session.language,
            "multi_country_mode": False,  # default placeholder
            "notes": notes,
            "status": db_session.status,
            "created_at": db_session.created_at.isoformat() + "Z" if db_session.created_at else None,
            "updated_at": db_session.updated_at.isoformat() + "Z" if db_session.updated_at else None,
        }

    def list_heatmap_points(self, species: str | None = None) -> list[dict]:
        query = self.db.query(DbSession).filter(DbSession.latitude.isnot(None), DbSession.longitude.isnot(None))
        if species:
            query = query.filter(DbSession.species == species)
            
        sessions = query.all()
        points = []
        for s in sessions:
            best_trial = None
            max_score = -1.0
            noise_values = []
            
            for t in s.trials:
                if t.ambient_noise_db is not None:
                    noise_values.append(float(t.ambient_noise_db))
                
                score = float(t.computed_score) if t.computed_score is not None else 0.0
                if t.manual_reaction == "reaction_yes":
                    score = max(score, 0.9)
                elif t.manual_reaction == "reaction_weak":
                    score = max(score, 0.5)
                    
                if score > max_score:
                    max_score = score
                    best_trial = t
                    
            best_name = "未検出"
            if best_trial:
                cand = self.db.query(DbCandidate).filter(DbCandidate.id == best_trial.candidate_id).first()
                if cand:
                    best_name = cand.display_name
                else:
                    best_name = best_trial.playback_text
                    
            avg_noise = sum(noise_values) / len(noise_values) if noise_values else None
            
            points.append({
                "session_id": s.id,
                "species": s.species,
                "latitude": float(s.latitude),
                "longitude": float(s.longitude),
                "best_candidate_name": best_name,
                "highest_score": float(max(0.0, max_score)) if best_trial else 0.0,
                "avg_ambient_noise_db": avg_noise,
                "created_at": s.created_at.isoformat() + "Z" if s.created_at else None
            })
        return points


class CandidateRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list(
        self,
        species: str | None,
        country_code: str | None,
        language_code: str | None,
        q: str | None,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        query = self.db.query(DbCandidate).filter(DbCandidate.enabled == True)
        if species:
            query = query.filter(DbCandidate.species == species)
        if country_code:
            query = query.filter(DbCandidate.country == country_code)
        if language_code:
            query = query.filter(DbCandidate.language == language_code)
        if q:
            query = query.filter(DbCandidate.display_name.like(f"%{q}%"))

        total = query.count()
        start = (page - 1) * page_size
        rows = query.offset(start).limit(page_size).all()
        return [self._to_dict(c) for c in rows], total

    def create(self, payload: dict) -> dict:
        candidate_id = make_id("cand")
        # mapping fields
        mapped_payload = {
            "id": candidate_id,
            "display_name": payload.get("name"),
            "species": payload.get("species"),
            "country": payload.get("country_code"),
            "language": payload.get("language_code"),
        }
        db_cand = DbCandidate(**mapped_payload)
        self.db.add(db_cand)
        self.db.commit()
        self.db.refresh(db_cand)
        return self._to_dict(db_cand)

    def update(self, candidate_id: str, payload: dict) -> dict:
        db_cand = self.db.query(DbCandidate).filter(DbCandidate.id == candidate_id).first()
        if not db_cand:
            raise AppError("NOT_FOUND", "candidate not found", status_code=404)
        if "name" in payload:
            db_cand.display_name = payload["name"]
        if "country_code" in payload:
            db_cand.country = payload["country_code"]
        if "language_code" in payload:
            db_cand.language = payload["language_code"]
        if "active" in payload:
            db_cand.enabled = payload["active"]
        self.db.commit()
        self.db.refresh(db_cand)
        return self._to_dict(db_cand)

    def delete(self, candidate_id: str) -> None:
        db_cand = self.db.query(DbCandidate).filter(DbCandidate.id == candidate_id).first()
        if not db_cand:
            raise AppError("NOT_FOUND", "candidate not found", status_code=404)
        db_cand.enabled = False
        self.db.commit()

    def _to_dict(self, db_cand: DbCandidate) -> dict:
        return {
            "candidate_id": db_cand.id,
            "name": db_cand.display_name,
            "species": db_cand.species,
            "country_code": db_cand.country,
            "language_code": db_cand.language,
            "active": db_cand.enabled,
            "created_at": db_cand.created_at.isoformat() + "Z" if db_cand.created_at else None,
        }


class TrialRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, session_id: str, payload: dict) -> dict:
        # 存在チェック
        session_exists = self.db.query(DbSession).filter(DbSession.id == session_id).first()
        if not session_exists:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        candidate_exists = self.db.query(DbCandidate).filter(DbCandidate.id == payload.get("candidate_id")).first()
        if not candidate_exists:
            raise AppError("NOT_FOUND", "candidate not found", status_code=404)

        trial_id = make_id("trl")
        mapped_payload = {
            "id": trial_id,
            "session_id": session_id,
            "candidate_id": payload.get("candidate_id"),
            "playback_text": payload.get("variant_text"),
            "voice_profile_id": payload.get("voice_type"),
            "started_at": payload.get("played_at") or datetime.utcnow(),
            "manual_reaction": payload.get("manual_flag"),
            "ambient_noise_db": payload.get("ambient_noise_db"),
        }
        db_trial = DbTrial(**mapped_payload)
        self.db.add(db_trial)
        self.db.commit()
        self.db.refresh(db_trial)
        return self._to_dict(db_trial)

    def save_features(self, trial_id: str, payload: dict) -> dict:
        trial_exists = self.db.query(DbTrial).filter(DbTrial.id == trial_id).first()
        if not trial_exists:
            raise AppError("NOT_FOUND", "trial not found", status_code=404)

        valid_payload = {
            "gaze_shift_score": payload.get("gaze_shift_score", 0.0),
            "head_turn_score": payload.get("head_turn_score", 0.0),
            "ear_motion_score": payload.get("ear_motion_score", 0.0),
            "approach_score": payload.get("approach_score", 0.0),
            "vocalization_score": payload.get("vocalization_score", 0.0),
            "repeatability_score": payload.get("repeatability_score", 0.0),
            "latency_ms": payload.get("latency_ms"),
            "manual_score": payload.get("manual_score"),
            "model_version": payload.get("model_version")
        }

        db_features = DbReactionFeatures(id=make_id("ftr"), trial_id=trial_id, **valid_payload)
        self.db.add(db_features)
        self.db.commit()
        self.db.refresh(db_features)
        return {
            "trial_id": db_features.trial_id,
            "gaze_shift_score": float(db_features.gaze_shift_score),
            "ear_motion_score": float(db_features.ear_motion_score),
            "head_turn_score": float(db_features.head_turn_score),
            "posture_change_score": float(payload.get("posture_change_score", 0.0)),
            "approach_score": float(db_features.approach_score),
            "vocalization_score": float(db_features.vocalization_score),
            "repeatability_score": float(db_features.repeatability_score),
            "latency_ms": db_features.latency_ms,
            "manual_score": float(db_features.manual_score) if db_features.manual_score is not None else None,
            "model_version": db_features.model_version
        }

    def _to_dict(self, db_trial: DbTrial) -> dict:
        return {
            "trial_id": db_trial.id,
            "session_id": db_trial.session_id,
            "candidate_id": db_trial.candidate_id,
            "variant_text": db_trial.playback_text,
            "voice_type": db_trial.voice_profile_id,
            "modulation_type": "unknown", # default/mock placeholder
            "played_at": db_trial.started_at.isoformat() + "Z" if db_trial.started_at else None,
            "manual_flag": db_trial.manual_reaction,
            "ambient_noise_db": float(db_trial.ambient_noise_db) if db_trial.ambient_noise_db is not None else None,
        }
