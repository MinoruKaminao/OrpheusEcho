from __future__ import annotations

from collections import defaultdict

from app.core.responses import AppError
from app.repositories.in_memory import InMemoryStore


class RankingService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store
        self.ranking = self  # Self-compatibility if needed

    def rank_session(self, session_id: str) -> list[dict]:
        """セッション内の試行反応を評価し、有力候補の参考スコアを算出する。"""
        if session_id not in self.store.sessions:
            raise AppError("NOT_FOUND", "session not found", status_code=404)

        score_by_candidate: dict[str, float] = defaultdict(float)
        trial_counts: dict[str, int] = defaultdict(int)
        best_features_by_candidate: dict[str, tuple[dict, float]] = {}

        for trial in self.store.trials.values():
            if trial.session_id != session_id:
                continue

            trial_counts[trial.candidate_id] += 1
            
            # 手動反応に基づく基本スコア (w8 = 0.40 用のベーススコア)
            base = 0.1
            if trial.manual_flag == "reaction_yes":
                base = 0.9
            elif trial.manual_flag == "reaction_weak":
                base = 0.45
            else:
                base = 0.1

            # AI特徴量による推論補助（存在する場合）
            feature = self.store.features.get(trial.trial_id)
            if feature:
                # latency_ms から latency_score (0.0 〜 1.0) を算出
                latency_ms = feature.latency_ms if feature.latency_ms is not None else 3000
                latency_score = max(0.0, min(1.0, 1.0 - (float(latency_ms) / 3000.0)))
                
                # Phase 3 スコア算出公式 (w1〜w8の加重ブレンド)
                trial_score = (
                    0.20 * float(feature.head_turn_score)         # w1
                    + 0.15 * float(feature.gaze_shift_score)      # w2
                    + 0.05 * float(feature.ear_motion_score)      # w3
                    + 0.10 * float(feature.approach_score)        # w4
                    + 0.03 * float(feature.vocalization_score)    # w5
                    + 0.05 * float(latency_score)                 # w6
                    + 0.02 * float(feature.repeatability_score)   # w7
                    + 0.40 * base                                 # w8 (manual)
                )
                
                # 最も高いスコアを叩き出した試行の特徴量と手動判定結果を記録（Explanation生成用）
                if trial.candidate_id not in best_features_by_candidate or trial_score > best_features_by_candidate[trial.candidate_id][1]:
                    best_features_by_candidate[trial.candidate_id] = ({
                        "head_turn": float(feature.head_turn_score),
                        "gaze_shift": float(feature.gaze_shift_score),
                        "ear_motion": float(feature.ear_motion_score),
                        "approach": float(feature.approach_score),
                        "vocalization": float(feature.vocalization_score),
                        "latency_ms": latency_ms,
                        "repeatability": float(feature.repeatability_score),
                        "manual_flag": trial.manual_flag
                    }, trial_score)
            else:
                # 特徴量が存在しない場合は手動判定をそのまま 100% としてスケール
                trial_score = base
            
            # 最大参考スコアを採用（0.99を上限とする参考値）
            score_by_candidate[trial.candidate_id] = max(
                score_by_candidate[trial.candidate_id], min(trial_score, 0.99)
            )

        ranked = sorted(score_by_candidate.items(), key=lambda x: x[1], reverse=True)
        result: list[dict] = []
        for candidate_id, score in ranked:
            cand = self.store.candidates.get(candidate_id)
            if not cand:
                continue
            
            # 試行回数が少ない場合は、スコアの確実性に疑義があるため uncertainty_flag を立てる
            trials_cnt = trial_counts[candidate_id]
            uncertain = trials_cnt < 2

            # Explainability Engine: 信頼度（confidence）と根拠テキスト（explanation）の決定
            confidence = "low"
            explanation = "試行回数が不足しているため、参考スコアの信頼性が低い状態です。複数回の呼びかけテストを行ってください。"
            source = "manual"
            model_version = None

            if candidate_id in best_features_by_candidate:
                source = "model_assisted"
                model_version = "lightweight-v1.0.0"
                feat_dict, _ = best_features_by_candidate[candidate_id]
                
                # 信頼度の決定
                if trials_cnt >= 2:
                    if feat_dict["repeatability"] >= 0.60:
                        confidence = "high"
                    else:
                        confidence = "medium"
                else:
                    confidence = "low"
                
                # 根拠テキスト（Explanation）の動的生成
                observations = []
                if feat_dict["head_turn"] >= 0.70:
                    observations.append("素早い頭部回転")
                if feat_dict["gaze_shift"] >= 0.70:
                    observations.append("強い注視（視線移動）")
                if feat_dict["approach"] >= 0.70:
                    observations.append("スピーカーへの接近行動")
                if feat_dict["ear_motion"] >= 0.70:
                    observations.append("耳の方向転換")
                if feat_dict["vocalization"] >= 0.50:
                    observations.append("鳴き声・発声")

                if feat_dict["manual_flag"] == "reaction_yes" and not observations:
                    observations.append("目視での明らかな反応")
                
                if observations:
                    obs_str = "、".join(observations)
                    latency_sec = float(feat_dict["latency_ms"]) / 1000.0
                    explanation = f"呼びかけに対し、{obs_str}が観察されました（反応遅延: {latency_sec:.1f}秒）。"
                    if trials_cnt >= 2:
                        explanation += f" 反応の再現性（{feat_dict['repeatability']:.0%}）が認められます。"
                else:
                    explanation = "呼びかけに対し、AI動作マーカー上の顕著な動作変化は観察されませんでした。"
            else:
                # 特徴量なしの手動判定のみの場合
                if trials_cnt >= 1:
                    confidence = "low"
                    explanation = "手動入力のみによる参考記録です。AI自動動作解析データは含まれていません。"

            result.append({
                "candidate_id": candidate_id,
                "name": cand.name,
                "score": round(score, 2),
                "uncertainty_flag": uncertain,
                "confidence": confidence,
                "explanation": explanation,
                "source": source,
                "model_version": model_version
            })
        return result

    def refine(self, session_id: str) -> list[dict]:
        """上位の有力候補名をベースに、ニックネームや愛称による再探索用の候補を展開する。"""
        ranked = self.rank_session(session_id)
        top = ranked[:3]
        refined: list[dict] = []
        
        session_info = self.store.sessions.get(session_id)
        country_code = session_info.country_code if session_info else "JP"
        language_code = session_info.language_code if session_info else "ja-JP"
        species = session_info.species if session_info else "dog"
        
        db = getattr(self.store, "db", None)
        if db:
            from app.repositories.country_dictionary_repository import CountryDictionaryRepository
            from app.services.country_dictionary_service import CountryDictionaryService
            dict_repo = CountryDictionaryRepository(db)
            dict_service = CountryDictionaryService(dict_repo)
            
            for item in top:
                refined.append(item)
                
                candidates = dict_service.generate_refined_candidates(
                    base_name=item["name"],
                    country_code=country_code,
                    language_code=language_code,
                    species=species,
                )
                for index, cand in enumerate(candidates):
                    ref_id = f"{item['candidate_id']}_ref_{index}"
                    # Ensure duplicate names aren't added
                    if any(r["name"] == cand["name"] for r in refined):
                        continue
                    refined.append({
                        "candidate_id": ref_id,
                        "name": cand["name"],
                        "score": round(max(item["score"] - 0.05, 0.0), 2),
                        "uncertainty_flag": True,
                        "confidence": "low",
                        "explanation": f"有力候補「{item['name']}」から展開された{cand['refinement_type']}候補です。追加検証を行ってください。",
                        "source": "model_assisted",
                        "model_version": "refine-multilingual-v1.0.0"
                    })
        else:
            from app.domain.country_rules import get_nickname_variants
            for item in top:
                refined.append(item)
                nicks = get_nickname_variants(item["name"], language_code)
                for nick in nicks:
                    if any(r["name"] == nick for r in refined):
                        continue
                    refined.append({
                        "candidate_id": f"{item['candidate_id']}_nick_{nick}",
                        "name": nick,
                        "score": round(max(item["score"] - 0.05, 0.0), 2),
                        "uncertainty_flag": True,
                        "confidence": "low",
                        "explanation": f"有力候補「{item['name']}」から展開された愛称候補です。追加検証を行ってください。",
                        "source": "model_assisted",
                        "model_version": "lightweight-nick-v1.0.0"
                    })
        return refined

