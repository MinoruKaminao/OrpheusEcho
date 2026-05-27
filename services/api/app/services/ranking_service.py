from __future__ import annotations

from collections import defaultdict

from app.core.responses import AppError
from app.repositories.in_memory import InMemoryStore


class RankingService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store

    def rank_session(self, session_id: str) -> list[dict]:
        """セッション内の試行反応を評価し、有力候補の参考スコアを算出する。"""
        if session_id not in self.store.sessions:
            raise AppError("NOT_FOUND", "session not found", status_code=404)

        score_by_candidate: dict[str, float] = defaultdict(float)
        trial_counts: dict[str, int] = defaultdict(int)

        for trial in self.store.trials.values():
            if trial.session_id != session_id:
                continue

            trial_counts[trial.candidate_id] += 1
            # 手動反応をベースに初期スコア（参考値）を計算
            base = 0.1
            if trial.manual_flag == "reaction_yes":
                base = 0.5
            elif trial.manual_flag == "reaction_weak":
                base = 0.25

            # AI特徴量による推論補助（存在する場合）
            feature = self.store.features.get(trial.trial_id)
            if feature:
                feature_avg = (
                    feature.gaze_shift_score
                    + feature.ear_motion_score
                    + feature.head_turn_score
                    + feature.posture_change_score
                    + feature.approach_score
                    + feature.vocalization_score
                    + feature.repeatability_score
                ) / 7.0
                base = (base + feature_avg) / 2.0

            # 複数回試行時の最大参考スコアを採用（0.99を上限とする参考値）
            score_by_candidate[trial.candidate_id] = max(
                score_by_candidate[trial.candidate_id], min(base, 0.99)
            )

        # スコアの降順にソートして有力候補ランキングを構成
        ranked = sorted(score_by_candidate.items(), key=lambda x: x[1], reverse=True)
        result: list[dict] = []
        for candidate_id, score in ranked:
            cand = self.store.candidates.get(candidate_id)
            if not cand:
                continue
            
            # 試行回数が少ない場合は、スコアの確実性に疑義があるため uncertainty_flag を立てる
            uncertain = trial_counts[candidate_id] < 2

            result.append({
                "candidate_id": candidate_id,
                "name": cand.name,
                "score": round(score, 2),
                "uncertainty_flag": uncertain
            })
        return result

    def refine(self, session_id: str) -> list[dict]:
        """上位の有力候補名をベースに、ニックネームや愛称による再探索用の候補を展開する。"""
        ranked = self.rank_session(session_id)
        top = ranked[:3]
        refined: list[dict] = []
        for item in top:
            # 元の有力候補を維持
            refined.append(item)
            # 愛称バリエーションを一時的に生成（スコアは参考としてやや低めに設定）
            refined.append(
                {
                    "candidate_id": f"{item['candidate_id']}_nick",
                    "name": f"{item['name']}ちゃん",
                    "score": round(max(item["score"] - 0.05, 0.0), 2),
                    "uncertainty_flag": True
                }
            )
        return refined
