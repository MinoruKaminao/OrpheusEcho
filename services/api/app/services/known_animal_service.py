from __future__ import annotations

from app.repositories.known_animal_repository import KnownAnimalRepository


class KnownAnimalService:
    def __init__(self, repository: KnownAnimalRepository) -> None:
        self.repository = repository

    def create(self, payload: dict) -> dict:
        return self.repository.create(payload)

    def get(self, animal_id: str) -> dict:
        return self.repository.get(animal_id)

    def update(self, animal_id: str, payload: dict) -> dict:
        return self.repository.update(animal_id, payload)

    def add_alias(self, animal_id: str, alias: str) -> dict:
        return self.repository.add_alias(animal_id, alias)

    def create_image_metadata(self, animal_id: str, payload: dict) -> dict:
        return self.repository.create_image_metadata(animal_id, payload)

    def update_annotation(self, image_id: str, payload: dict) -> dict:
        return self.repository.update_annotation(image_id, payload)
