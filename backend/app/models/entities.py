from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Literal


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


Species = Literal["dog", "cat"]


@dataclass
class Session:
    session_id: str
    species: Species
    temp_animal_id: str | None = None
    location_text: str | None = None
    coat_color: str | None = None
    age_hint: str | None = None
    country_code: str | None = None
    language_code: str | None = None
    multi_country_mode: bool = False
    notes: str | None = None
    status: str = "created"
    created_at: datetime = field(default_factory=now_utc)
    updated_at: datetime = field(default_factory=now_utc)


@dataclass
class Candidate:
    candidate_id: str
    name: str
    species: Species
    country_code: str | None = None
    language_code: str | None = None
    active: bool = True
    created_at: datetime = field(default_factory=now_utc)
    updated_at: datetime = field(default_factory=now_utc)


@dataclass
class Trial:
    trial_id: str
    session_id: str
    candidate_id: str
    variant_text: str
    voice_type: str
    modulation_type: str
    played_at: datetime
    manual_flag: str | None = None
    created_at: datetime = field(default_factory=now_utc)


@dataclass
class ReactionFeatures:
    trial_id: str
    gaze_shift_score: float
    ear_motion_score: float
    head_turn_score: float
    posture_change_score: float
    approach_score: float
    vocalization_score: float
    repeatability_score: float

