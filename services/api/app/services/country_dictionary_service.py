from __future__ import annotations

from app.domain.country_rules import get_nickname_variants
from app.domain.phonetic_rules import compute_phonetic_similarity
from app.repositories.country_dictionary_repository import CountryDictionaryRepository
from app.models.db_models import DbCountry, DbLanguage, DbCountryDictionary


class CountryDictionaryService:
    def __init__(self, repo: CountryDictionaryRepository) -> None:
        self.repo = repo

    def get_countries(self) -> list[DbCountry]:
        return self.repo.list_countries()

    def get_languages(self) -> list[DbLanguage]:
        return self.repo.list_languages()

    def get_dictionary_items(
        self,
        country_code: str | None = None,
        language_code: str | None = None,
        species: str | None = None,
    ) -> list[DbCountryDictionary]:
        return self.repo.list_dictionary_items(
            country_code=country_code,
            language_code=language_code,
            species=species,
        )

    def create_dictionary_item(self, payload: dict) -> DbCountryDictionary:
        return self.repo.create_dictionary_item(payload)

    def generate_refined_candidates(
        self,
        base_name: str,
        country_code: str,
        language_code: str,
        species: str,
    ) -> list[dict]:
        """Generate variations (nicknames) and find phonetically similar names in the dictionary.

        Returns list of candidate dicts:
        {
            "name": str,
            "reading": str | None,
            "refinement_type": "nickname" | "phonetic_similarity",
            "similarity_score": float,
        }
        """
        refined = []

        # 1. Nicknames
        nicknames = get_nickname_variants(base_name, language_code)
        for nick in nicknames:
            refined.append({
                "name": nick,
                "reading": None,  # Suffix added, phonetic reading not explicitly parsed
                "refinement_type": "nickname",
                "similarity_score": 0.8,  # Arbitrary default score for nicknames
            })

        # Find base name's reading in dictionary to compare
        base_items = self.repo.list_dictionary_items(
            country_code=country_code,
            language_code=language_code,
            species=species,
        )
        
        base_reading = None
        for item in base_items:
            if item.name.lower() == base_name.lower():
                base_reading = item.reading
                break

        if not base_reading:
            base_reading = base_name

        # 2. Phonetic sound-alike recommendations
        similar_items = []
        for item in base_items:
            if item.name.lower() == base_name.lower():
                continue
            similarity = compute_phonetic_similarity(base_reading, item.reading or item.name)
            if similarity >= 0.5:
                similar_items.append({
                    "name": item.name,
                    "reading": item.reading,
                    "refinement_type": "phonetic_similarity",
                    "similarity_score": similarity,
                })

        similar_items.sort(key=lambda x: x["similarity_score"], reverse=True)
        refined.extend(similar_items[:5])  # Top 5 similar names

        return refined
