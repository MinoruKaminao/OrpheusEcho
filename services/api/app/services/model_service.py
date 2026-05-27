from __future__ import annotations

import json
import zipfile
import threading
import time
from pathlib import Path
from typing import List
from datetime import datetime

from sqlalchemy.orm import Session
from app.repositories.model_repository import ModelRepository
from app.models.db_models import (
    DbSession,
    DbTrial,
    DbReactionFeatures,
    DbKnownAnimal,
    DbTrainingSession,
    DbTrainingTrial,
    DbMLModel
)
from app.core.responses import AppError
from app.utils.ids import make_id


class ModelService:
    def __init__(self, repository: ModelRepository, db: Session) -> None:
        self.repository = repository
        self.db = db

    def get_current_model(self) -> dict:
        model = self.repository.get_current_active()
        if not model:
            # Fallback to default v1.0.0 if nothing active yet
            default_model = self.db.query(DbMLModel).filter(DbMLModel.version == "1.0.0").first()
            if default_model:
                return self.repository._model_to_dict(default_model)
            raise AppError("NOT_FOUND", "No active model version registered", status_code=404)
        return model

    def get_model_versions(self) -> List[dict]:
        return self.repository.get_all()

    def check_update(self, current_version: str) -> dict:
        current_active = self.repository.get_current_active()
        if not current_active:
            # Seed model if registered
            seed_model = self.db.query(DbMLModel).filter(DbMLModel.version == "1.0.0").first()
            if seed_model:
                current_active = self.repository._model_to_dict(seed_model)
            else:
                return {
                    "update_available": False,
                    "latest_version": current_version,
                    "download_url": ""
                }
        
        # Simple comparison: check if the version strings are different
        update_available = current_active["version"] != current_version
        return {
            "update_available": update_available,
            "latest_version": current_active["version"],
            "download_url": current_active["download_url"]
        }

    def apply_update(self, version: str) -> dict:
        updated = self.repository.set_active_version(version)
        return {
            "success": True,
            "version": updated["version"]
        }

    def export_data(self, session_ids: List[str], training_session_ids: List[str], anonymize: bool = True) -> dict:
        job_id = make_id("job_exp")
        
        # 1. Gather normal sessions
        exported_sessions = []
        for s_id in session_ids:
            db_session = self.db.query(DbSession).filter(DbSession.id == s_id).first()
            if not db_session:
                continue
            
            # Extract trials
            trials = []
            for t in db_session.trials:
                feat = t.features
                features_dict = {}
                if feat:
                    features_dict = {
                        "head_turn_score": float(feat.head_turn_score),
                        "gaze_shift_score": float(feat.gaze_shift_score),
                        "ear_motion_score": float(feat.ear_motion_score),
                        "approach_score": float(feat.approach_score),
                        "vocalization_score": float(feat.vocalization_score),
                        "latency_ms": feat.latency_ms,
                        "repeatability_score": float(feat.repeatability_score),
                        "manual_score": float(feat.manual_score) if feat.manual_score is not None else None,
                    }
                trials.append({
                    "trial_id": t.id,
                    "playback_text": t.playback_text,
                    "manual_reaction": t.manual_reaction,
                    "computed_score": float(t.computed_score) if t.computed_score is not None else None,
                    "features": features_dict
                })
            
            exported_sessions.append({
                "session_id": db_session.id,
                "species": db_session.species,
                "status": db_session.status,
                "notes": "ANONYMIZED" if anonymize else db_session.animal_notes,
                "trials": trials
            })

        # 2. Gather training sessions (Check privacy consent)
        exported_training_sessions = []
        for ts_id in training_session_ids:
            db_tr_session = self.db.query(DbTrainingSession).filter(DbTrainingSession.id == ts_id).first()
            if not db_tr_session:
                continue
            
            # Consent Check
            animal = db_tr_session.known_animal
            if not animal or animal.owner_consent_status != "agreed":
                # Exclude from training if consent is withdrawn
                continue
            
            trials = []
            for t in db_tr_session.trials:
                trials.append({
                    "trial_id": t.id,
                    "called_name": "ANONYMIZED" if anonymize else t.called_name,
                    "is_true_name": t.is_true_name,
                    "is_alias": t.is_alias,
                    "modulation_type": t.modulation_type,
                    "playback_source": t.playback_source,
                    "manual_reaction": t.manual_reaction
                })

            exported_training_sessions.append({
                "training_session_id": db_tr_session.id,
                "known_animal_id": db_tr_session.known_animal_id,
                "speaker_type": db_tr_session.speaker_type,
                "environment_type": db_tr_session.environment_type,
                "purpose": db_tr_session.purpose,
                "status": db_tr_session.status,
                "trials": trials
            })

        # 3. Write ZIP archive
        exports_dir = Path(__file__).resolve().parent.parent.parent / "exports"
        exports_dir.mkdir(parents=True, exist_ok=True)
        zip_path = exports_dir / f"training_export_{job_id}.zip"

        export_payload = {
            "exported_at": datetime.utcnow().isoformat() + "Z",
            "sessions": exported_sessions,
            "training_sessions": exported_training_sessions
        }

        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zip_file:
            zip_file.writestr("dataset.json", json.dumps(export_payload, ensure_ascii=False, indent=2))

        # 4. Save job record
        job_data = {
            "id": job_id,
            "job_type": "export",
            "status": "completed",
            "progress": 100.0,
            "result_metadata": {
                "download_url": f"http://localhost:8001/exports/training_export_{job_id}.zip",
                "sessions_count": len(exported_sessions),
                "training_sessions_count": len(exported_training_sessions)
            }
        }
        self.repository.create_job(job_data)
        
        return {
            "job_id": job_id,
            "status": "ready",
            "download_url": f"http://localhost:8001/exports/training_export_{job_id}.zip"
        }

    def start_sync_and_train(self, export_job_id: str) -> dict:
        sync_job_id = make_id("job_sync")
        
        # Create pending job
        job_data = {
            "id": sync_job_id,
            "job_type": "sync_learning",
            "status": "pending",
            "progress": 0.0,
            "result_metadata": {
                "export_job_id": export_job_id
            }
        }
        self.repository.create_job(job_data)

        # Start simulated training thread
        thread = threading.Thread(
            target=self._run_training_pipeline,
            args=(sync_job_id, export_job_id),
            daemon=True
        )
        thread.start()

        return {
            "sync_job_id": sync_job_id,
            "status": "pending"
        }

    def get_sync_job_status(self, job_id: str) -> dict:
        job = self.repository.get_job(job_id)
        if not job:
            raise AppError("NOT_FOUND", "Sync job not found", status_code=404)
        
        meta = json.loads(job["result_metadata"]) if job["result_metadata"] else {}
        return {
            "sync_job_id": job["id"],
            "status": job["status"],
            "progress": job["progress"],
            "result_metadata": meta
        }

    def _run_training_pipeline(self, sync_job_id: str, export_job_id: str):
        # We need a separate DB session for background thread
        # Because Sqlite / Sqlalchemy handles multithreading with separate sessions
        from app.core.database import SessionLocal
        db = SessionLocal()
        try:
            repo = ModelRepository(db)
            
            # Step 1: Running
            repo.update_job(sync_job_id, {"status": "running", "progress": 20.0})
            time.sleep(0.5)

            # Step 2: Validate and Read ZIP dataset
            exports_dir = Path(__file__).resolve().parent.parent.parent / "exports"
            zip_path = exports_dir / f"training_export_{export_job_id}.zip"
            
            if not zip_path.exists():
                repo.update_job(sync_job_id, {
                    "status": "failed",
                    "progress": 100.0,
                    "result_metadata": {"error": f"Export package not found: {export_job_id}"}
                })
                return

            repo.update_job(sync_job_id, {"progress": 40.0})
            time.sleep(0.5)

            # Extract weights mapping logic
            with zipfile.ZipFile(zip_path, "r") as zip_ref:
                dataset_bytes = zip_ref.read("dataset.json")
                dataset = json.loads(dataset_bytes.decode("utf-8"))
            
            # Data Cleaning & Validation (Check if we have training data with consent)
            training_sessions = dataset.get("training_sessions", [])
            sessions = dataset.get("sessions", [])
            
            # Step 3: Simulated Learning Loop
            # We fit weights to optimize F1 Score based on reaction strength
            repo.update_job(sync_job_id, {"progress": 60.0})
            time.sleep(0.5)

            # Calculate optimized dummy weights based on average features
            # (Rule-based feedback modeling)
            total_trials = 0
            feature_sums = {
                "head_turn": 0.0, "gaze_shift": 0.0, "ear_motion": 0.0,
                "approach": 0.0, "vocalization": 0.0, "repeatability": 0.0
            }
            for s in sessions:
                for t in s.get("trials", []):
                    f = t.get("features", {})
                    if f:
                        total_trials += 1
                        feature_sums["head_turn"] += f.get("head_turn_score", 0.0)
                        feature_sums["gaze_shift"] += f.get("gaze_shift_score", 0.0)
                        feature_sums["ear_motion"] += f.get("ear_motion_score", 0.0)
                        feature_sums["approach"] += f.get("approach_score", 0.0)
                        feature_sums["vocalization"] += f.get("vocalization_score", 0.0)
                        feature_sums["repeatability"] += f.get("repeatability_score", 0.0)

            # Normalization and dummy weights adaptation
            weights = {
                "w_head_turn": 0.15, "w_gaze_shift": 0.15, "w_ear_motion": 0.10,
                "w_approach": 0.15, "w_vocalization": 0.10, "w_latency": 0.10,
                "w_repeatability": 0.10, "w_manual": 0.15
            }
            if total_trials > 0:
                # Modulate slightly to simulate learning adaptation
                weights["w_head_turn"] = round(0.1 + (feature_sums["head_turn"] / total_trials) * 0.1, 3)
                weights["w_gaze_shift"] = round(0.1 + (feature_sums["gaze_shift"] / total_trials) * 0.1, 3)
                # Ensure sum is close to 1.0 (auto normalized)
                current_sum = sum(weights.values())
                for k in weights:
                    weights[k] = round(weights[k] / current_sum, 3)

            # Accuracy / Evaluation
            # Simulated model evaluation yields improvement metrics
            base_f1 = 0.785
            improved_f1 = min(0.99, base_f1 + (len(training_sessions) * 0.01) + (total_trials * 0.005))
            
            repo.update_job(sync_job_id, {"progress": 80.0})
            time.sleep(0.5)

            # Step 4: Write lightweight model file
            new_version = f"1.1.{int(time.time()) % 1000}"
            model_filename = f"model_v{new_version}.json"
            model_path = exports_dir / model_filename

            model_payload = {
                "model_version": new_version,
                "weights": weights,
                "hyperparameters": {
                    "confidence_high_threshold": 0.80,
                    "confidence_medium_threshold": 0.60
                },
                "accuracy_metrics": {
                    "f1_score": improved_f1,
                    "auc": min(0.99, improved_f1 + 0.02)
                }
            }

            with open(model_path, "w", encoding="utf-8") as f:
                json.dump(model_payload, f, ensure_ascii=False, indent=2)

            # Step 5: Register model metadata
            model_data = {
                "id": make_id("mdl"),
                "version": new_version,
                "description": f"Batch trained model utilizing {len(training_sessions)} training sessions and {total_trials} exploration trials.",
                "accuracy_score": improved_f1,
                "status": "draft",
                "download_url": f"http://localhost:8001/exports/{model_filename}"
            }
            repo.create_model(model_data)
            repo.set_active_version(new_version)

            # Complete Job
            repo.update_job(sync_job_id, {
                "status": "completed",
                "progress": 100.0,
                "result_metadata": {
                    "new_version": new_version,
                    "accuracy_score": improved_f1,
                    "download_url": f"http://localhost:8001/exports/{model_filename}"
                }
            })

        except Exception as e:
            try:
                repo = ModelRepository(db)
                repo.update_job(sync_job_id, {
                    "status": "failed",
                    "progress": 100.0,
                    "result_metadata": {"error": str(e)}
                })
            except Exception as inner_e:
                print("Failed to save error status to sync job:", inner_e)
        finally:
            db.close()
