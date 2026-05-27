from pathlib import Path

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse

from app.api.router import api_router
from app.core.database import Base, engine, SessionLocal
from app.core.responses import app_exception_handler, validation_exception_handler
from app.models.db_models import DbCandidate, DbCountry, DbLanguage, DbCountryDictionary, DbTTSProfile



def create_app() -> FastAPI:
    # 起動時にデータベーステーブルを自動作成 (開発用・SQLiteフォールバック用)
    Base.metadata.create_all(bind=engine)
    
    # 候補テーブルが空の場合はシードデータを追加
    db = SessionLocal()
    try:
        if db.query(DbCandidate).count() == 0:
            seeds = [
                # JP
                DbCandidate(id="cand_001", display_name="モモ", species="dog", country="JP", language="ja-JP", reading="モモ", popularity_rank=1),
                DbCandidate(id="cand_002", display_name="モカ", species="dog", country="JP", language="ja-JP", reading="モカ", popularity_rank=2),
                DbCandidate(id="cand_003", display_name="ルナ", species="cat", country="JP", language="ja-JP", reading="ルナ", popularity_rank=1),
                DbCandidate(id="cand_004", display_name="ココ", species="dog", country="JP", language="ja-JP", reading="ココ", popularity_rank=3),
                DbCandidate(id="cand_005", display_name="レオ", species="cat", country="JP", language="ja-JP", reading="レオ", popularity_rank=2),
                # US
                DbCandidate(id="cand_us_001", display_name="Max", species="dog", country="US", language="en-US", reading="mæks", popularity_rank=1),
                DbCandidate(id="cand_us_002", display_name="Bella", species="dog", country="US", language="en-US", reading="ˈbɛlə", popularity_rank=2),
                DbCandidate(id="cand_us_003", display_name="Charlie", species="dog", country="US", language="en-US", reading="ˈtʃɑːrli", popularity_rank=3),
                DbCandidate(id="cand_us_004", display_name="Luna", species="cat", country="US", language="en-US", reading="ˈluːnə", popularity_rank=1),
                DbCandidate(id="cand_us_005", display_name="Oliver", species="cat", country="US", language="en-US", reading="ˈɒlɪvər", popularity_rank=2),
            ]
            db.add_all(seeds)
            db.commit()

        if db.query(DbCountry).count() == 0:
            countries = [
                DbCountry(code="JP", name="日本", default_language="ja-JP"),
                DbCountry(code="US", name="United States", default_language="en-US"),
                DbCountry(code="GB", name="United Kingdom", default_language="en-GB"),
            ]
            db.add_all(countries)
            db.commit()

        if db.query(DbLanguage).count() == 0:
            languages = [
                DbLanguage(code="ja-JP", name="日本語"),
                DbLanguage(code="en-US", name="English (US)"),
                DbLanguage(code="en-GB", name="English (UK)"),
            ]
            db.add_all(languages)
            db.commit()

        if db.query(DbCountryDictionary).count() == 0:
            dictionary_items = [
                # JP Dog
                DbCountryDictionary(country_code="JP", language_code="ja-JP", species="dog", name="モモ", reading="モモ", category="popular", popularity_rank=1),
                DbCountryDictionary(country_code="JP", language_code="ja-JP", species="dog", name="モカ", reading="モカ", category="popular", popularity_rank=2),
                DbCountryDictionary(country_code="JP", language_code="ja-JP", species="dog", name="ココ", reading="ココ", category="popular", popularity_rank=3),
                # JP Cat
                DbCountryDictionary(country_code="JP", language_code="ja-JP", species="cat", name="タマ", reading="タマ", category="popular", popularity_rank=1),
                DbCountryDictionary(country_code="JP", language_code="ja-JP", species="cat", name="ミーコ", reading="ミーコ", category="popular", popularity_rank=2),
                # US Dog
                DbCountryDictionary(country_code="US", language_code="en-US", species="dog", name="Max", reading="mæks", category="popular", popularity_rank=1),
                DbCountryDictionary(country_code="US", language_code="en-US", species="dog", name="Bella", reading="ˈbɛlə", category="popular", popularity_rank=2),
                DbCountryDictionary(country_code="US", language_code="en-US", species="dog", name="Charlie", reading="ˈtʃɑːrli", category="popular", popularity_rank=3),
                # US Cat
                DbCountryDictionary(country_code="US", language_code="en-US", species="cat", name="Luna", reading="ˈluːnə", category="popular", popularity_rank=1),
                DbCountryDictionary(country_code="US", language_code="en-US", species="cat", name="Oliver", reading="ˈɒlɪvər", category="popular", popularity_rank=2),
            ]
            db.add_all(dictionary_items)
            db.commit()

        if db.query(DbTTSProfile).count() == 0:
            tts_profiles = [
                DbTTSProfile(id="tts_jp_female", language_code="ja-JP", voice_name="Kyoko", gender="female", speaking_rate=1.0, pitch=1.0, engine_type="mock"),
                DbTTSProfile(id="tts_jp_male", language_code="ja-JP", voice_name="Otoya", gender="male", speaking_rate=1.0, pitch=1.0, engine_type="mock"),
                DbTTSProfile(id="tts_en_female", language_code="en-US", voice_name="Samantha", gender="female", speaking_rate=1.0, pitch=1.0, engine_type="mock"),
                DbTTSProfile(id="tts_en_male", language_code="en-US", voice_name="Daniel", gender="male", speaking_rate=1.0, pitch=1.0, engine_type="mock"),
            ]
            db.add_all(tts_profiles)
            db.commit()


        # Seed ML model
        from datetime import datetime
        import json
        from app.models.db_models import DbMLModel
        
        exports_dir = Path(__file__).resolve().parent.parent / "exports"
        exports_dir.mkdir(parents=True, exist_ok=True)
        model_file = exports_dir / "model_v1.0.0.json"
        if not model_file.exists():
            default_payload = {
                "model_version": "1.0.0",
                "weights": {
                    "w_head_turn": 0.15, "w_gaze_shift": 0.15, "w_ear_motion": 0.10,
                    "w_approach": 0.15, "w_vocalization": 0.10, "w_latency": 0.10,
                    "w_repeatability": 0.10, "w_manual": 0.15
                },
                "hyperparameters": {
                    "confidence_high_threshold": 0.80,
                    "confidence_medium_threshold": 0.60
                },
                "accuracy_metrics": {
                    "f1_score": 0.75,
                    "auc": 0.78
                }
            }
            with open(model_file, "w", encoding="utf-8") as f:
                json.dump(default_payload, f, ensure_ascii=False, indent=2)

        if db.query(DbMLModel).count() == 0:
            seed_model = DbMLModel(
                id="mdl_seed_100",
                version="1.0.0",
                description="Default rule-based and initial lightweight scoring model.",
                accuracy_score=0.7500,
                status="active",
                download_url="http://localhost:8001/exports/model_v1.0.0.json",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(seed_model)
            db.commit()
    finally:
        db.close()


    app = FastAPI(title="Orpheus Echo API", version="0.1.0")
    app.include_router(api_router, prefix="/api")

    from fastapi.staticfiles import StaticFiles
    exports_dir = Path(__file__).resolve().parent.parent / "exports"
    exports_dir.mkdir(parents=True, exist_ok=True)
    app.mount("/exports", StaticFiles(directory=str(exports_dir)), name="exports")

    @app.get("/")
    def mobile_ui() -> FileResponse:
        ui_path = Path(__file__).resolve().parent / "ui" / "index.html"
        return FileResponse(ui_path)

    app.add_exception_handler(Exception, app_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    return app


app = create_app()
