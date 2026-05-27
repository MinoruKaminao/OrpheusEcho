from fastapi import APIRouter, Depends

from app.api.deps import get_known_animal_service
from app.core.responses import ok_response
from app.schemas.known_animal import (
    KnownAnimalCreate,
    KnownAnimalUpdate,
    AliasCreate,
    ImageMetadataRegister,
    AnnotationUpdate
)
from app.services.known_animal_service import KnownAnimalService

router = APIRouter()


@router.post("/known-animals")
def create_known_animal(
    payload: KnownAnimalCreate,
    service: KnownAnimalService = Depends(get_known_animal_service)
) -> dict:
    animal = service.create(payload.model_dump())
    return ok_response(animal)


@router.get("/known-animals/{known_animal_id}")
def get_known_animal(
    known_animal_id: str,
    service: KnownAnimalService = Depends(get_known_animal_service)
) -> dict:
    return ok_response(service.get(known_animal_id))


@router.patch("/known-animals/{known_animal_id}")
def update_known_animal(
    known_animal_id: str,
    payload: KnownAnimalUpdate,
    service: KnownAnimalService = Depends(get_known_animal_service)
) -> dict:
    return ok_response(service.update(known_animal_id, payload.model_dump(exclude_none=True)))


@router.post("/known-animals/{known_animal_id}/aliases")
def add_alias(
    known_animal_id: str,
    payload: AliasCreate,
    service: KnownAnimalService = Depends(get_known_animal_service)
) -> dict:
    animal = service.add_alias(known_animal_id, payload.alias)
    return ok_response(animal)


@router.post("/known-animals/{known_animal_id}/images")
def register_image(
    known_animal_id: str,
    payload: ImageMetadataRegister,
    service: KnownAnimalService = Depends(get_known_animal_service)
) -> dict:
    res = service.create_image_metadata(known_animal_id, payload.model_dump())
    return ok_response(res)


@router.patch("/images/{image_id}/annotations")
def update_annotation(
    image_id: str,
    payload: AnnotationUpdate,
    service: KnownAnimalService = Depends(get_known_animal_service)
) -> dict:
    res = service.update_annotation(image_id, payload.model_dump(exclude_none=True))
    return ok_response(res)
