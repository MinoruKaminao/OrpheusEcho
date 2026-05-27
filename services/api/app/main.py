from pathlib import Path

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse

from app.api.router import api_router
from app.core.database import Base, engine, SessionLocal
from app.core.responses import app_exception_handler, validation_exception_handler
from app.models.db_models import DbCandidate


def create_app() -> FastAPI:
    # 起動時にデータベーステーブルを自動作成 (開発用・SQLiteフォールバック用)
    Base.metadata.create_all(bind=engine)
    
    # 候補テーブルが空の場合はシードデータを追加
    db = SessionLocal()
    try:
        if db.query(DbCandidate).count() == 0:
            seeds = [
                DbCandidate(id="cand_001", display_name="モモ", species="dog", country="JP", language="ja-JP"),
                DbCandidate(id="cand_002", display_name="モカ", species="dog", country="JP", language="ja-JP"),
                DbCandidate(id="cand_003", display_name="ルナ", species="cat", country="JP", language="ja-JP"),
                DbCandidate(id="cand_004", display_name="ココ", species="dog", country="JP", language="ja-JP"),
                DbCandidate(id="cand_005", display_name="レオ", species="cat", country="JP", language="ja-JP"),
            ]
            db.add_all(seeds)
            db.commit()
    finally:
        db.close()

    app = FastAPI(title="Orpheus Echo API", version="0.1.0")
    app.include_router(api_router, prefix="/api")

    @app.get("/")
    def mobile_ui() -> FileResponse:
        ui_path = Path(__file__).resolve().parent / "ui" / "index.html"
        return FileResponse(ui_path)

    app.add_exception_handler(Exception, app_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    return app


app = create_app()
