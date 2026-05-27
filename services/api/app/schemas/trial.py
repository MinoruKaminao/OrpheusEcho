from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class TrialCreate(BaseModel):
    candidate_id: str
    variant_text: str
    voice_type: str
    modulation_type: str
    played_at: datetime
    manual_flag: str | None = None


class TrialFeatureCreate(BaseModel):
    gaze_shift_score: float
    ear_motion_score: float
    head_turn_score: float
    posture_change_score: float
    approach_score: float
    vocalization_score: float
    repeatability_score: float
