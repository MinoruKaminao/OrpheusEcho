from __future__ import annotations

from dataclasses import asdict

from app.models.entities import Candidate, ReactionFeatures, Session, Trial


class InMemoryStore:
    def __init__(self) -> None:
        self.sessions: dict[str, Session] = {}
        self.candidates: dict[str, Candidate] = {}
        self.trials: dict[str, Trial] = {}
        self.features: dict[str, ReactionFeatures] = {}
        self._seed_candidates()

    def _seed_candidates(self) -> None:
        seeds = [
            Candidate(candidate_id="cand_001", name="モモ", species="dog", country_code="JP", language_code="ja-JP"),
            Candidate(candidate_id="cand_002", name="モカ", species="dog", country_code="JP", language_code="ja-JP"),
            Candidate(candidate_id="cand_003", name="ルナ", species="cat", country_code="JP", language_code="ja-JP"),
        ]
        for c in seeds:
            self.candidates[c.candidate_id] = c

    @staticmethod
    def to_dict(obj: object) -> dict:
        return asdict(obj)

