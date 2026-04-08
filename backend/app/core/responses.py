from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def build_meta(request_id: str | None = None, **extra: object) -> dict[str, object]:
    meta: dict[str, object] = {
        "request_id": request_id or f"req_{uuid4().hex[:12]}",
        "timestamp": utc_now_iso(),
    }
    meta.update(extra)
    return meta


class ErrorBody(BaseModel):
    code: str
    message: str


def ok_response(data: object, request_id: str | None = None, **meta_extra: object) -> dict[str, object]:
    return {
        "data": data,
        "meta": build_meta(request_id=request_id, **meta_extra),
        "error": None,
    }


def error_response(
    code: str,
    message: str,
    status_code: int,
    request_id: str | None = None,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "data": None,
            "meta": build_meta(request_id=request_id),
            "error": ErrorBody(code=code, message=message).model_dump(),
        },
    )


class AppError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


async def app_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    if isinstance(exc, AppError):
        return error_response(code=exc.code, message=exc.message, status_code=exc.status_code)
    return error_response(code="INTERNAL_SERVER_ERROR", message="unexpected error", status_code=500)


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    first_error = exc.errors()[0] if exc.errors() else None
    message = first_error.get("msg", "validation error") if first_error else "validation error"
    return error_response(code="VALIDATION_ERROR", message=message, status_code=422)
