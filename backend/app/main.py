from pathlib import Path

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse

from app.api.router import api_router
from app.core.responses import app_exception_handler, validation_exception_handler


def create_app() -> FastAPI:
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
