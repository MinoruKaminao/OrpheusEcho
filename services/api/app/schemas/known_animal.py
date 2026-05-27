from __future__ import annotations

from typing import Literal, List
from pydantic import BaseModel


class KnownAnimalCreate(BaseModel):
    id: str | None = None  # Allow client-generated ID
    species: Literal["dog", "cat"]
    true_name: str
    aliases: List[str] | None = None
    sex: Literal["male", "female", "unknown"] | None = None
    age_range: str | None = None
    breed: str | None = None
    coat_color: str | None = None
    owner_consent_status: Literal["agreed", "withdrawn"] = "agreed"


class KnownAnimalRead(BaseModel):
    id: str
    species: str
    true_name: str
    aliases: List[str] | None = None
    sex: str | None = None
    age_range: str | None = None
    breed: str | None = None
    coat_color: str | None = None
    owner_consent_status: str
    created_at: str


class KnownAnimalUpdate(BaseModel):
    true_name: str | None = None
    aliases: List[str] | None = None
    sex: Literal["male", "female", "unknown"] | None = None
    age_range: str | None = None
    breed: str | None = None
    coat_color: str | None = None
    owner_consent_status: Literal["agreed", "withdrawn"] | None = None


class AliasCreate(BaseModel):
    alias: str


class ImageMetadataRegister(BaseModel):
    file_name: str
    content_type: str
    pose_type: str | None = None
    image_quality: str | None = None


class ImageMetadataRead(BaseModel):
    image_id: str
    upload_url: str


class AnnotationUpdate(BaseModel):
    pose_type: str | None = None
    image_quality: str | None = None
    annotations: str | None = None  # JSON string
