from __future__ import annotations

import hashlib
from pathlib import Path
from app.repositories.tts_repository import TTSRepository
from app.models.db_models import DbTTSProfile
from app.core.responses import AppError


class TTSService:
    def __init__(self, repo: TTSRepository, export_dir: str = "exports") -> None:
        self.repo = repo
        self.export_dir = Path(export_dir)

    def get_profiles(self) -> list[DbTTSProfile]:
        return self.repo.list_profiles()

    def get_profile(self, profile_id: str) -> DbTTSProfile | None:
        return self.repo.get_profile(profile_id)

    def create_profile(self, payload: dict) -> DbTTSProfile:
        return self.repo.create_profile(payload)

    def generate_preview(self, text: str, profile_id: str, host_url: str = "http://localhost:8001") -> str:
        profile = self.repo.get_profile(profile_id)
        if not profile:
            raise AppError("NOT_FOUND", "TTS profile not found", status_code=404)

        # Generate a unique hash for the preview file to prevent duplicate synthesis
        hash_input = f"{text}_{profile.id}_{profile.speaking_rate}_{profile.pitch}"
        text_hash = hashlib.md5(hash_input.encode("utf-8")).hexdigest()
        filename = f"tts_{text_hash}.m4a"

        # Ensure exports/tts directory exists
        tts_dir = self.export_dir / "tts"
        tts_dir.mkdir(parents=True, exist_ok=True)

        file_path = tts_dir / filename
        if not file_path.exists():
            # Write a dummy binary stream to represent the compiled speech sound
            file_path.write_bytes(b"\x00" * 100)

        return f"{host_url.rstrip('/')}/exports/tts/{filename}"
