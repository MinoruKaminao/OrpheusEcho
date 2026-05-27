from __future__ import annotations

import json
from datetime import datetime
from sqlalchemy.orm import Session
from app.core.responses import AppError
from app.models.db_models import DbKnownAnimal, DbMediaAsset, DbImageAnnotation
from app.utils.ids import make_id


class KnownAnimalRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, payload: dict) -> dict:
        animal_id = payload.get("id") or make_id("ka")
        
        # Check idempotency
        exists = self.db.query(DbKnownAnimal).filter(DbKnownAnimal.id == animal_id).first()
        if exists:
            return self.update(animal_id, payload)

        aliases_str = json.dumps(payload.get("aliases") or [])
        db_animal = DbKnownAnimal(
            id=animal_id,
            species=payload.get("species"),
            true_name=payload.get("true_name"),
            aliases=aliases_str,
            sex=payload.get("sex"),
            age_range=payload.get("age_range"),
            breed=payload.get("breed"),
            coat_color=payload.get("coat_color"),
            owner_consent_status=payload.get("owner_consent_status", "agreed"),
            created_at=datetime.utcnow()
        )
        self.db.add(db_animal)
        self.db.commit()
        self.db.refresh(db_animal)
        return self._to_dict(db_animal)

    def get(self, animal_id: str) -> dict:
        db_animal = self.db.query(DbKnownAnimal).filter(DbKnownAnimal.id == animal_id).first()
        if not db_animal:
            raise AppError("NOT_FOUND", "Known animal not found", status_code=404)
        return self._to_dict(db_animal)

    def update(self, animal_id: str, payload: dict) -> dict:
        db_animal = self.db.query(DbKnownAnimal).filter(DbKnownAnimal.id == animal_id).first()
        if not db_animal:
            raise AppError("NOT_FOUND", "Known animal not found", status_code=404)
        
        if "true_name" in payload and payload["true_name"] is not None:
            db_animal.true_name = payload["true_name"]
        if "aliases" in payload and payload["aliases"] is not None:
            db_animal.aliases = json.dumps(payload["aliases"])
        if "sex" in payload and payload["sex"] is not None:
            db_animal.sex = payload["sex"]
        if "age_range" in payload and payload["age_range"] is not None:
            db_animal.age_range = payload["age_range"]
        if "breed" in payload and payload["breed"] is not None:
            db_animal.breed = payload["breed"]
        if "coat_color" in payload and payload["coat_color"] is not None:
            db_animal.coat_color = payload["coat_color"]
        if "owner_consent_status" in payload and payload["owner_consent_status"] is not None:
            db_animal.owner_consent_status = payload["owner_consent_status"]

        self.db.commit()
        self.db.refresh(db_animal)
        return self._to_dict(db_animal)

    def add_alias(self, animal_id: str, alias: str) -> dict:
        db_animal = self.db.query(DbKnownAnimal).filter(DbKnownAnimal.id == animal_id).first()
        if not db_animal:
            raise AppError("NOT_FOUND", "Known animal not found", status_code=404)
        
        aliases = json.loads(db_animal.aliases) if db_animal.aliases else []
        if alias not in aliases:
            aliases.append(alias)
            db_animal.aliases = json.dumps(aliases)
            self.db.commit()
            self.db.refresh(db_animal)
        return self._to_dict(db_animal)

    def create_image_metadata(self, animal_id: str, payload: dict) -> dict:
        animal_exists = self.db.query(DbKnownAnimal).filter(DbKnownAnimal.id == animal_id).first()
        if not animal_exists:
            raise AppError("NOT_FOUND", "Known animal not found", status_code=404)
        
        image_id = make_id("img")
        db_media = DbMediaAsset(
            id=image_id,
            known_animal_id=animal_id,
            media_type="image",
            storage_url=f"/exports/known_animals/{animal_id}/images/{image_id}.jpg",
            created_at=datetime.utcnow()
        )
        self.db.add(db_media)
        self.db.commit()
        
        db_annotation = DbImageAnnotation(
            id=make_id("ant"),
            media_asset_id=image_id,
            pose_type=payload.get("pose_type"),
            image_quality=payload.get("image_quality"),
            created_at=datetime.utcnow()
        )
        self.db.add(db_annotation)
        self.db.commit()
        
        return {
            "image_id": image_id,
            "upload_url": f"http://localhost:8001/api/v1/uploads/{image_id}"
        }

    def update_annotation(self, image_id: str, payload: dict) -> dict:
        db_annotation = self.db.query(DbImageAnnotation).filter(DbImageAnnotation.media_asset_id == image_id).first()
        if not db_annotation:
            raise AppError("NOT_FOUND", "Image annotation not found", status_code=404)
        
        if "pose_type" in payload and payload["pose_type"] is not None:
            db_annotation.pose_type = payload["pose_type"]
        if "image_quality" in payload and payload["image_quality"] is not None:
            db_annotation.image_quality = payload["image_quality"]
        if "annotations" in payload and payload["annotations"] is not None:
            db_annotation.annotations = payload["annotations"]
            
        self.db.commit()
        self.db.refresh(db_annotation)
        return {
            "image_id": image_id,
            "pose_type": db_annotation.pose_type,
            "image_quality": db_annotation.image_quality,
            "annotations": db_annotation.annotations
        }

    def _to_dict(self, db_animal: DbKnownAnimal) -> dict:
        aliases = json.loads(db_animal.aliases) if db_animal.aliases else []
        return {
            "id": db_animal.id,
            "species": db_animal.species,
            "true_name": db_animal.true_name,
            "aliases": aliases,
            "sex": db_animal.sex,
            "age_range": db_animal.age_range,
            "breed": db_animal.breed,
            "coat_color": db_animal.coat_color,
            "owner_consent_status": db_animal.owner_consent_status,
            "created_at": db_animal.created_at.isoformat() + "Z" if db_animal.created_at else None
        }
