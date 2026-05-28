from __future__ import annotations

import os
from pathlib import Path
from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.repositories.joke_repository import JokeRepository
from app.domain.joke_guardrails import validate_nickname


class JokeService:
    def __init__(self, repository: JokeRepository) -> None:
        self.repository = repository

    def create_session(self, payload: dict) -> dict:
        return self.repository.create_session(payload)

    def get_session(self, session_id: str) -> dict:
        return self.repository.get_session(session_id)

    def upload_image(self, session_id: str, filename: str, content: bytes) -> dict:
        # 画像の保存先パス設定
        exports_dir = Path(__file__).resolve().parent.parent.parent / "exports"
        joke_dir = exports_dir / "joke_sessions" / session_id
        joke_dir.mkdir(parents=True, exist_ok=True)

        ext = Path(filename).suffix or ".jpg"
        target_path = joke_dir / f"face{ext}"
        
        # ファイル書き込み
        with open(target_path, "wb") as f:
            f.write(content)

        # 顔検出のスタブ判定 (画像データが 100 バイト以上であれば顔ありとする)
        has_face = len(content) > 100

        relative_path = f"joke_sessions/{session_id}/face{ext}"
        self.repository.update_session_image(session_id, relative_path)

        return {
            "image_path": relative_path,
            "has_face": has_face
        }

    def generate_candidates(self, session_id: str) -> list[dict]:
        session = self.repository.get_session(session_id)
        country = session.get("selected_country")
        language = session.get("selected_language")
        age_band = session.get("selected_age_band")
        tone = session.get("tone_type")
        
        print(f"DEBUG JOKE: session_id={session_id}, country={country}, language={language}", flush=True)

        # 候補マスタから取得
        raw_candidates = self.repository.list_candidates(country, language)
        print(f"DEBUG JOKE: raw_candidates count={len(raw_candidates)}", flush=True)

        # 安全ガードレールでフィルタリング
        safe_candidates = [c for c in raw_candidates if validate_nickname(c["name"])]
        print(f"DEBUG JOKE: safe_candidates count={len(safe_candidates)}", flush=True)

        # 年代カテゴリやトーンに基づく Heuristics ランキング / 調整
        # 例: 年代が 30s_like, 40s_like などでトーンが formal の場合は "joke_safe" タイプ（役職など）を優先
        # 年代が子供やカジュアルトーンなら "nickname" を優先
        def get_priority(cand: dict) -> int:
            cand_type = cand.get("type")
            if tone == "formal":
                if cand_type == "joke_safe":
                    return 0
                return 1
            else:
                if cand_type == "nickname":
                    return 0
                return 1

        # ソートして返却
        sorted_candidates = sorted(safe_candidates, key=get_priority)

        # 上位 5 件に絞る（少なすぎず多すぎず適度な数に）
        return sorted_candidates[:5]

    def create_reaction(self, session_id: str, payload: dict) -> dict:
        return self.repository.create_reaction(session_id, payload)

    def get_results(self, session_id: str) -> dict:
        session = self.repository.get_session(session_id)
        reactions = self.repository.list_reactions(session_id)

        if not reactions:
            # 反応が記録されていない場合
            return {
                "joke_session_id": session_id,
                "top_candidates": [],
                "result_card_url": None
            }

        # ウケ反応（総合スコア）順にソート
        sorted_reactions = sorted(reactions, key=lambda r: r["composite_score"], reverse=True)

        top_candidates = []
        for rx in sorted_reactions[:3]:  # 上位 3 件
            try:
                cand = self.repository.get_candidate(rx["joke_profile_id"])
                top_candidates.append({
                    "name": cand["name"],
                    "composite_score": rx["composite_score"]
                })
            except AppError:
                continue

        # セッションの完了日時を記録
        self.repository.complete_session(session_id)

        # 結果カード画像の URL を構築 (ダミーとして、最優秀ニックネーム入りの結果カードURLを返す)
        # 実際にはフロント側で ImageRenderer を使うか、サーバーで生成する。
        # ここでは static / exports パスへアクセスする URL を生成
        card_url = None
        if top_candidates:
            best_name = top_candidates[0]["name"]
            card_filename = f"result_card.png"
            # 実際にはここにモックの画像ファイルを書き出すか、スタブURLにする
            card_url = f"http://localhost:8001/exports/joke_sessions/{session_id}/{card_filename}"

            # モックのテキストファイルを結果カード代わりに書き出す
            exports_dir = Path(__file__).resolve().parent.parent.parent / "exports"
            joke_dir = exports_dir / "joke_sessions" / session_id
            joke_dir.mkdir(parents=True, exist_ok=True)
            with open(joke_dir / card_filename, "w") as f:
                f.write(f"JOKE RESULT CARD\nSession ID: {session_id}\nBest Nickname: {best_name}\nScore: {top_candidates[0]['composite_score']}")

        return {
            "joke_session_id": session_id,
            "top_candidates": top_candidates,
            "result_card_url": card_url
        }
