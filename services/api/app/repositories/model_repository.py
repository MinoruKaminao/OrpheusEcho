from __future__ import annotations

import json
from datetime import datetime
from typing import List

from sqlalchemy.orm import Session
from app.core.responses import AppError
from app.models.db_models import DbMLModel, DbSyncJob
from app.utils.ids import make_id


class ModelRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_current_active(self) -> dict | None:
        db_model = self.db.query(DbMLModel).filter(DbMLModel.status == "active").order_by(DbMLModel.updated_at.desc()).first()
        if not db_model:
            return None
        return self._model_to_dict(db_model)

    def get_all(self) -> List[dict]:
        db_models = self.db.query(DbMLModel).order_by(DbMLModel.version.desc()).all()
        return [self._model_to_dict(m) for m in db_models]

    def get_by_version(self, version: str) -> dict | None:
        db_model = self.db.query(DbMLModel).filter(DbMLModel.version == version).first()
        if not db_model:
            return None
        return self._model_to_dict(db_model)

    def create_model(self, payload: dict) -> dict:
        model_id = payload.get("id") or make_id("mdl")
        
        # Check uniqueness of version
        version = payload.get("version")
        exists = self.db.query(DbMLModel).filter(DbMLModel.version == version).first()
        if exists:
            raise AppError("CONFLICT", f"Model version {version} already exists", status_code=409)

        db_model = DbMLModel(
            id=model_id,
            version=version,
            description=payload.get("description"),
            accuracy_score=payload.get("accuracy_score"),
            status=payload.get("status", "draft"),
            download_url=payload.get("download_url"),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        self.db.add(db_model)
        self.db.commit()
        self.db.refresh(db_model)
        return self._model_to_dict(db_model)

    def update_model(self, model_id: str, payload: dict) -> dict:
        db_model = self.db.query(DbMLModel).filter(DbMLModel.id == model_id).first()
        if not db_model:
            raise AppError("NOT_FOUND", "ML Model not found", status_code=404)

        if "description" in payload:
            db_model.description = payload["description"]
        if "accuracy_score" in payload:
            db_model.accuracy_score = payload["accuracy_score"]
        if "status" in payload:
            db_model.status = payload["status"]
        if "download_url" in payload:
            db_model.download_url = payload["download_url"]
            
        db_model.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_model)
        return self._model_to_dict(db_model)

    def set_active_version(self, version: str) -> dict:
        db_model = self.db.query(DbMLModel).filter(DbMLModel.version == version).first()
        if not db_model:
            raise AppError("NOT_FOUND", f"Model version {version} not found", status_code=404)

        # Set all other active models to deprecated
        active_models = self.db.query(DbMLModel).filter(DbMLModel.status == "active").all()
        for m in active_models:
            if m.id != db_model.id:
                m.status = "deprecated"
                m.updated_at = datetime.utcnow()

        db_model.status = "active"
        db_model.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_model)
        return self._model_to_dict(db_model)

    # Sync Job Methods
    def create_job(self, payload: dict) -> dict:
        job_id = payload.get("id") or make_id("job")
        
        db_job = DbSyncJob(
            id=job_id,
            job_type=payload.get("job_type"),
            status=payload.get("status", "pending"),
            progress=payload.get("progress", 0.0),
            result_metadata=json.dumps(payload.get("result_metadata") or {}),
            created_at=datetime.utcnow()
        )
        self.db.add(db_job)
        self.db.commit()
        self.db.refresh(db_job)
        return self._job_to_dict(db_job)

    def get_job(self, job_id: str) -> dict | None:
        db_job = self.db.query(DbSyncJob).filter(DbSyncJob.id == job_id).first()
        if not db_job:
            return None
        return self._job_to_dict(db_job)

    def update_job(self, job_id: str, payload: dict) -> dict:
        db_job = self.db.query(DbSyncJob).filter(DbSyncJob.id == job_id).first()
        if not db_job:
            raise AppError("NOT_FOUND", "Sync job not found", status_code=404)

        if "status" in payload:
            db_job.status = payload["status"]
        if "progress" in payload:
            db_job.progress = payload["progress"]
        if "result_metadata" in payload:
            db_job.result_metadata = json.dumps(payload["result_metadata"])

        self.db.commit()
        self.db.refresh(db_job)
        return self._job_to_dict(db_job)

    # Serializers
    def _model_to_dict(self, m: DbMLModel) -> dict:
        return {
            "id": m.id,
            "version": m.version,
            "description": m.description,
            "accuracy_score": float(m.accuracy_score) if m.accuracy_score is not None else None,
            "status": m.status,
            "download_url": m.download_url,
            "created_at": m.created_at,
            "updated_at": m.updated_at
        }

    def _job_to_dict(self, j: DbSyncJob) -> dict:
        return {
            "id": j.id,
            "job_type": j.job_type,
            "status": j.status,
            "progress": float(j.progress),
            "result_metadata": j.result_metadata,
            "created_at": j.created_at
        }
