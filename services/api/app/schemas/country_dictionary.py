from __future__ import annotations

from pydantic import BaseModel


class CountryRead(BaseModel):
    code: str
    name: str
    default_language: str

    class Config:
        orm_mode = True
        from_attributes = True


class LanguageRead(BaseModel):
    code: str
    name: str

    class Config:
        orm_mode = True
        from_attributes = True


class DictionaryItemRead(BaseModel):
    id: int
    country_code: str
    language_code: str
    species: str
    name: str
    reading: str | None = None
    category: str
    popularity_rank: int

    class Config:
        orm_mode = True
        from_attributes = True


class DictionaryItemCreate(BaseModel):
    country_code: str
    language_code: str
    species: str
    name: str
    reading: str | None = None
    category: str
    popularity_rank: int


class TTSProfileRead(BaseModel):
    id: str
    language_code: str
    voice_name: str
    gender: str
    speaking_rate: float
    pitch: float
    engine_type: str

    class Config:
        orm_mode = True
        from_attributes = True


class TTSPreviewRequest(BaseModel):
    text: str
    tts_profile_id: str


class TTSPreviewResponse(BaseModel):
    audio_url: str
    status: str
