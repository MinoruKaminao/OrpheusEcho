from __future__ import annotations

from typing import Literal
from pydantic import BaseModel


class JokeSessionCreate(BaseModel):
    selected_country: str | None = None
    selected_language: str | None = None
    selected_age_band: str | None = None
    tone_type: str | None = None


class JokeSessionRead(BaseModel):
    joke_session_id: str
    selected_country: str | None
    selected_language: str | None
    selected_age_band: str | None
    tone_type: str | None
    image_path: str | None
    created_at: str | None
    completed_at: str | None


class JokeCandidateRead(BaseModel):
    joke_profile_id: str
    name: str
    type: str
    language_code: str | None
    country_code: str | None
    is_active: bool


class JokeReactionCreate(BaseModel):
    joke_profile_id: str
    smile_score: float = 0.0
    laugh_score: float = 0.0
    manual_reaction: Literal["reaction_yes", "reaction_no", "reaction_meh"] | None = None


class JokeReactionRead(BaseModel):
    joke_reaction_id: str
    joke_session_id: str
    joke_profile_id: str
    smile_score: float
    laugh_score: float
    manual_reaction: str | None
    composite_score: float
    created_at: str | None


class JokeResultCandidate(BaseModel):
    name: str
    composite_score: float


class JokeResultRead(BaseModel):
    joke_session_id: str
    top_candidates: list[JokeResultCandidate]
    result_card_url: str | None = None
