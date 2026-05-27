from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.db_models import DbCountry, DbLanguage, DbCountryDictionary


class CountryDictionaryRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_countries(self) -> list[DbCountry]:
        return self.db.query(DbCountry).all()

    def list_languages(self) -> list[DbLanguage]:
        return self.db.query(DbLanguage).all()

    def list_dictionary_items(
        self,
        country_code: str | None = None,
        language_code: str | None = None,
        species: str | None = None,
    ) -> list[DbCountryDictionary]:
        query = self.db.query(DbCountryDictionary)
        if country_code:
            query = query.filter(DbCountryDictionary.country_code == country_code)
        if language_code:
            query = query.filter(DbCountryDictionary.language_code == language_code)
        if species:
            query = query.filter(DbCountryDictionary.species == species)
        return query.order_by(DbCountryDictionary.popularity_rank.asc()).all()

    def create_dictionary_item(self, payload: dict) -> DbCountryDictionary:
        db_item = DbCountryDictionary(**payload)
        self.db.add(db_item)
        self.db.commit()
        self.db.refresh(db_item)
        return db_item
