from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel


class MLModelRead(BaseModel):
    id: str
    version: str
    description: str | None = None
    accuracy_score: float | None = None
    status: str
    download_url: str
    created_at: datetime
    updated_at: datetime


class ModelUpdateCheckRequest(BaseModel):
    current_version: str


class ModelUpdateCheckResponse(BaseModel):
    update_available: bool
    latest_version: str
    download_url: str


class ModelApplyUpdateRequest(BaseModel):
    version: str


class ModelApplyUpdateResponse(BaseModel):
    success: bool
    version: str


class SyncJobRead(BaseModel):
    id: str
    job_type: str
    status: str
    progress: float
    result_metadata: str | None = None
    created_at: datetime
