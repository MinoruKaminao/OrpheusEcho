from __future__ import annotations

from datetime import datetime
from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ErrorSchema(BaseModel):
    code: str
    message: str


class MetaSchema(BaseModel):
    request_id: str
    timestamp: datetime
    page: int | None = None
    page_size: int | None = None
    total: int | None = None


class Envelope(BaseModel, Generic[T]):
    data: T | None
    meta: MetaSchema
    error: ErrorSchema | None = None


class PaginationQuery(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)

