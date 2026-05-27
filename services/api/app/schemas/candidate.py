from __future__ import annotations

from typing import Literal

from pydantic import BaseModel


class CandidateCreate(BaseModel):
    name: str
    species: Literal["dog", "cat"]
    country_code: str | None = None
    language_code: str | None = None


class CandidateUpdate(BaseModel):
    name: str | None = None
    country_code: str | None = None
    language_code: str | None = None
    active: bool | None = None
