from __future__ import annotations

from typing import Literal

from pydantic import BaseModel


class SessionCreate(BaseModel):
    species: Literal["dog", "cat"]
    temp_animal_id: str | None = None
    location_text: str | None = None
    coat_color: str | None = None
    age_hint: str | None = None
    country_code: str | None = None
    language_code: str | None = None
    multi_country_mode: bool = False
    notes: str | None = None


class SessionUpdate(BaseModel):
    temp_animal_id: str | None = None
    location_text: str | None = None
    coat_color: str | None = None
    age_hint: str | None = None
    country_code: str | None = None
    language_code: str | None = None
    multi_country_mode: bool | None = None
    notes: str | None = None
    status: str | None = None

