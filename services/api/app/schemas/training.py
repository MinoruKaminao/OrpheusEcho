from __future__ import annotations

from typing import Literal
from pydantic import BaseModel


class TrainingSessionCreate(BaseModel):
    id: str | None = None  # Allow client-generated ID
    known_animal_id: str
    speaker_type: str  # "owner" | "family" | "stranger"
    environment_type: str  # "indoor" | "outdoor"
    purpose: str


class TrainingSessionRead(BaseModel):
    id: str
    known_animal_id: str
    speaker_type: str
    environment_type: str
    purpose: str
    status: str
    created_at: str
    completed_at: str | None = None


class TrainingTrialCreate(BaseModel):
    id: str | None = None  # Allow client-generated ID
    called_name: str
    is_true_name: bool
    is_alias: bool
    modulation_type: str
    playback_source: str
    manual_reaction: Literal["reaction_yes", "reaction_weak", "reaction_no"] | None = None


class TrainingTrialRead(BaseModel):
    id: str
    training_session_id: str
    called_name: str
    is_true_name: bool
    is_alias: bool
    modulation_type: str
    playback_source: str
    manual_reaction: str | None = None
    created_at: str
