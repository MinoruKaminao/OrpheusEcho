from __future__ import annotations

from collections import defaultdict

from app.core.responses import AppError
from app.repositories.in_memory import InMemoryStore


class RankingService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store

    def rank_session(self, session_id: str) -> list[dict]:
        if session_id not in self.store.sessions:
            raise AppError("NOT_FOUND", "session not found", status_code=404)

        score_by_candidate: dict[str, float] = defaultdict(float)
        for trial in self.store.trials.values():
            if trial.session_id != session_id:
                continue

            base = 0.3 if trial.manual_flag == "reaction_yes" else 0.1
            feature = self.store.features.get(trial.trial_id)
            if feature:
                base += (
                    feature.gaze_shift_score
                    + feature.ear_motion_score
                    + feature.head_turn_score
                    + feature.posture_change_score
                    + feature.approach_score
                    + feature.vocalization_score
                    + feature.repeatability_score
                ) / 7.0
            score_by_candidate[trial.candidate_id] = max(score_by_candidate[trial.candidate_id], min(base, 0.99))

        ranked = sorted(score_by_candidate.items(), key=lambda x: x[1], reverse=True)
        result: list[dict] = []
        for candidate_id, score in ranked:
            cand = self.store.candidates.get(candidate_id)
            if not cand:
                continue
            result.append({"candidate_id": candidate_id, "name": cand.name, "score": round(score, 2)})
        return result

    def refine(self, session_id: str) -> list[dict]:
        ranked = self.rank_session(session_id)
        top = ranked[:3]
        refined = top.copy()
        for item in top:
            refined.append(
                {
                    "candidate_id": f"{item['candidate_id']}_nick",
                    "name": f"{item['name']}ちゃん",
                    "score": round(max(item["score"] - 0.05, 0.0), 2),
                }
            )
        return refined

