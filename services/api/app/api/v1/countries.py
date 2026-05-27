from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_country_dictionary_service
from app.core.responses import ok_response
from app.schemas.country_dictionary import CountryRead, LanguageRead, DictionaryItemRead, DictionaryItemCreate
from app.services.country_dictionary_service import CountryDictionaryService

router = APIRouter()


@router.get("/countries")
def list_countries(
    service: CountryDictionaryService = Depends(get_country_dictionary_service),
) -> dict:
    rows = service.get_countries()
    data = [CountryRead.from_orm(c).dict() for c in rows]
    return ok_response(data)


@router.get("/languages")
def list_languages(
    service: CountryDictionaryService = Depends(get_country_dictionary_service),
) -> dict:
    rows = service.get_languages()
    data = [LanguageRead.from_orm(l).dict() for l in rows]
    return ok_response(data)


@router.get("/country-dictionaries")
def list_dictionary_items(
    country_code: str | None = Query(None),
    language_code: str | None = Query(None),
    species: str | None = Query(None),
    service: CountryDictionaryService = Depends(get_country_dictionary_service),
) -> dict:
    rows = service.get_dictionary_items(
        country_code=country_code,
        language_code=language_code,
        species=species,
    )
    data = [DictionaryItemRead.from_orm(d).dict() for d in rows]
    return ok_response(data)


@router.post("/country-dictionaries")
def create_dictionary_item(
    payload: DictionaryItemCreate,
    service: CountryDictionaryService = Depends(get_country_dictionary_service),
) -> dict:
    item = service.create_dictionary_item(payload.dict())
    return ok_response(DictionaryItemRead.from_orm(item).dict())
