from __future__ import annotations

import csv
from dataclasses import asdict
import json
import os
from pathlib import Path

from app.core.responses import AppError
from app.repositories.in_memory import InMemoryStore
from app.services.ranking_service import RankingService


class ResultService:
    def __init__(self, store: InMemoryStore) -> None:
        self.store = store
        self.ranking = RankingService(store)

    def get_session_results(self, session_id: str) -> dict:
        session = self.store.sessions.get(session_id)
        if not session:
            raise AppError("NOT_FOUND", "session not found", status_code=404)

        # featuresをマージする
        trials = []
        for t in self.store.trials.values():
            if t.session_id == session_id:
                t_dict = asdict(t)
                # datetimeがあれば文字列にする
                if isinstance(t_dict.get("played_at"), os.PathLike) or hasattr(t_dict.get("played_at"), "isoformat"):
                    t_dict["played_at"] = t_dict["played_at"].isoformat() + "Z"
                
                feat = self.store.features.get(t.trial_id)
                if feat:
                    t_dict["features"] = asdict(feat)
                else:
                    t_dict["features"] = None
                trials.append(t_dict)
        
        top_candidates = self.ranking.rank_session(session_id)

        # session自体も辞書に変換 (dataclassオブジェクトかもしれないので)
        session_dict = asdict(session) if not isinstance(session, dict) else session
        if isinstance(session_dict.get("created_at"), os.PathLike) or hasattr(session_dict.get("created_at"), "isoformat"):
            session_dict["created_at"] = session_dict["created_at"].isoformat() + "Z"
        if isinstance(session_dict.get("updated_at"), os.PathLike) or hasattr(session_dict.get("updated_at"), "isoformat"):
            session_dict["updated_at"] = session_dict["updated_at"].isoformat() + "Z"

        return {
            "session": session_dict,
            "top_candidates": top_candidates,
            "trial_count": len(trials),
            "trials": trials,
        }

    def export(self, session_id: str, fmt: str) -> dict:
        if session_id not in self.store.sessions:
            raise AppError("NOT_FOUND", "session not found", status_code=404)
        if fmt not in {"pdf", "csv", "json"}:
            raise AppError("VALIDATION_ERROR", "format must be one of: pdf,csv,json", status_code=422)

        data = self.get_session_results(session_id)
        
        # エクスポートディレクトリの作成
        exports_dir = Path(__file__).resolve().parent.parent.parent / "exports"
        dest_dir = exports_dir / session_id
        dest_dir.mkdir(parents=True, exist_ok=True)
        filepath = dest_dir / f"result.{fmt}"

        if fmt == "json":
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2, default=lambda o: o.isoformat() + "Z" if hasattr(o, "isoformat") else str(o))

        elif fmt == "csv":
            with open(filepath, "w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow(["--- SESSION METADATA ---"])
                session = data["session"]
                writer.writerow(["Session ID", session["session_id"]])
                writer.writerow(["Species", session["species"]])
                writer.writerow(["Location", session.get("location_text") or ""])
                writer.writerow(["Temp ID", session.get("temp_animal_id") or ""])
                writer.writerow(["Coat Color", session.get("coat_color") or ""])
                writer.writerow(["Age Hint", session.get("age_hint") or ""])
                writer.writerow(["Notes", session.get("notes") or ""])
                writer.writerow(["Status", session["status"]])
                writer.writerow(["Created At", session.get("created_at") or ""])
                writer.writerow([])
                
                writer.writerow(["--- TOP RANKED CANDIDATES ---"])
                writer.writerow(["Name", "Score", "Uncertainty Flag"])
                for rank in data["top_candidates"]:
                    writer.writerow([rank["name"], rank["score"], rank["uncertainty_flag"]])
                writer.writerow([])
                
                writer.writerow(["--- EXPLORATION TRIALS ---"])
                writer.writerow([
                    "Trial ID", "Candidate Name", "Voice Type", "Modulation", 
                    "Reaction Type", "Gaze Shift", "Head Turn", "Ear Motion", 
                    "Approach", "Vocalization", "Repeatability", "Played At"
                ])
                for trial in data["trials"]:
                    feat = trial.get("features") or {}
                    writer.writerow([
                        trial["trial_id"],
                        trial["variant_text"],
                        trial["voice_type"],
                        trial.get("modulation_type") or "unknown",
                        trial.get("manual_flag") or "",
                        feat.get("gaze_shift_score", 0.0),
                        feat.get("head_turn_score", 0.0),
                        feat.get("ear_motion_score", 0.0),
                        feat.get("approach_score", 0.0),
                        feat.get("vocalization_score", 0.0),
                        feat.get("repeatability_score", 0.0),
                        trial.get("played_at") or ""
                    ])

        elif fmt == "pdf":
            self._generate_pdf(filepath, data)

        return {
            "session_id": session_id,
            "format": fmt,
            "status": "ready",
            "download_url": f"http://localhost:8001/exports/{session_id}/result.{fmt}",
        }

    def _generate_pdf(self, filepath: Path, data: dict):
        from reportlab.lib.pagesizes import letter
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib import colors
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont

        # 日本語フォントの登録
        font_paths = [
            "/System/Library/Fonts/Supplemental/AppleGothic.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
            "/System/Library/Fonts/AppleSDGothicNeo.ttc"
        ]
        font_name = "Helvetica"
        for fp in font_paths:
            if os.path.exists(fp):
                try:
                    pdfmetrics.registerFont(TTFont("Japanese", fp))
                    font_name = "Japanese"
                    break
                except:
                    pass

        doc = SimpleDocTemplate(str(filepath), pagesize=letter,
                                rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
        story = []
        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "ReportTitle",
            parent=styles["Title"],
            fontName=font_name,
            fontSize=20,
            leading=24,
            textColor=colors.HexColor("#1A202C"),
            alignment=0, # Left aligned
            spaceAfter=20
        )
        
        h1_style = ParagraphStyle(
            "Heading1_Custom",
            parent=styles["Heading1"],
            fontName=font_name,
            fontSize=14,
            leading=18,
            textColor=colors.HexColor("#2B6CB0"),
            spaceBefore=15,
            spaceAfter=8
        )
        
        body_style = ParagraphStyle(
            "Body_Custom",
            parent=styles["BodyText"],
            fontName=font_name,
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#4A5568")
        )

        story.append(Paragraph("Orpheus Echo 探索セッション結果レポート", title_style))
        story.append(Spacer(1, 10))

        # セッション基本情報のテーブル
        session = data["session"]
        meta_data = [
            [Paragraph("<b>セッションID:</b>", body_style), Paragraph(session["session_id"], body_style),
             Paragraph("<b>対象動物:</b>", body_style), Paragraph(session["species"], body_style)],
            [Paragraph("<b>探索場所:</b>", body_style), Paragraph(session.get("location_text") or "-", body_style),
             Paragraph("<b>仮ID:</b>", body_style), Paragraph(session.get("temp_animal_id") or "-", body_style)],
            [Paragraph("<b>毛色:</b>", body_style), Paragraph(session.get("coat_color") or "-", body_style),
             Paragraph("<b>推定年齢:</b>", body_style), Paragraph(session.get("age_hint") or "-", body_style)],
            [Paragraph("<b>備考メモ:</b>", body_style), Paragraph(session.get("notes") or "-", body_style),
             Paragraph("<b>作成日時:</b>", body_style), Paragraph(session.get("created_at") or "-", body_style)]
        ]
        meta_table = Table(meta_data, colWidths=[80, 180, 80, 180])
        meta_table.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F7FAFC")),
            ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#E2E8F0")),
            ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#EDF2F7")),
            ('TOPPADDING', (0,0), (-1,-1), 6),
            ('LEFTPADDING', (0,0), (-1,-1), 8),
            ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ]))
        
        story.append(Paragraph("セッション基本情報", h1_style))
        story.append(meta_table)
        story.append(Spacer(1, 15))

        # 有力候補ランキング
        story.append(Paragraph("推定有力呼称候補（上位）", h1_style))
        rank_headers = [Paragraph("<b>順位</b>", body_style), Paragraph("<b>候補名</b>", body_style), Paragraph("<b>参考スコア</b>", body_style), Paragraph("<b>信頼度フラグ</b>", body_style)]
        rank_rows = [rank_headers]
        for idx, rank in enumerate(data["top_candidates"]):
            uncertain = "検証不足(要追試)" if rank["uncertainty_flag"] else "高信頼"
            rank_rows.append([
                Paragraph(str(idx + 1), body_style),
                Paragraph(rank["name"], body_style),
                Paragraph(f"{rank['score']:.2f}", body_style),
                Paragraph(uncertain, body_style)
            ])
        rank_table = Table(rank_rows, colWidths=[40, 180, 100, 200])
        rank_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#EDF2F7")),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('TOPPADDING', (0,0), (-1,-1), 6),
            ('LEFTPADDING', (0,0), (-1,-1), 8),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ]))
        story.append(rank_table)
        story.append(Spacer(1, 15))

        # 試行履歴
        story.append(Paragraph("呼びかけ試行履歴ログ", h1_style))
        trial_headers = [
            Paragraph("<b>候補名</b>", body_style), 
            Paragraph("<b>手動反応</b>", body_style), 
            Paragraph("<b>頭部回転</b>", body_style), 
            Paragraph("<b>視線移動</b>", body_style), 
            Paragraph("<b>接近度</b>", body_style),
            Paragraph("<b>再現性</b>", body_style)
        ]
        trial_rows = [trial_headers]
        for trial in data["trials"]:
            feat = trial.get("features") or {}
            
            # 手動反応を日本語へ
            manual_map = {"reaction_yes": "反応あり", "reaction_weak": "弱い", "reaction_none": "反応なし"}
            manual_str = manual_map.get(trial.get("manual_flag") or "", "記録なし")
            
            trial_rows.append([
                Paragraph(trial["variant_text"], body_style),
                Paragraph(manual_str, body_style),
                Paragraph(f"{feat.get('head_turn_score', 0.0):.2f}", body_style),
                Paragraph(f"{feat.get('gaze_shift_score', 0.0):.2f}", body_style),
                Paragraph(f"{feat.get('approach_score', 0.0):.2f}", body_style),
                Paragraph(f"{feat.get('repeatability_score', 0.0):.2f}", body_style),
            ])
        trial_table = Table(trial_rows, colWidths=[100, 100, 80, 80, 80, 80])
        trial_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#EDF2F7")),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('TOPPADDING', (0,0), (-1,-1), 6),
            ('LEFTPADDING', (0,0), (-1,-1), 8),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ]))
        story.append(trial_table)

        doc.build(story)
