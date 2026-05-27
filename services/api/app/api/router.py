from fastapi import APIRouter

from app.api.v1 import candidates, health, results, sessions, trials

api_router = APIRouter()
api_router.include_router(health.router, prefix="/v1", tags=["health"])
api_router.include_router(sessions.router, prefix="/v1", tags=["sessions"])
api_router.include_router(candidates.router, prefix="/v1", tags=["candidates"])
api_router.include_router(trials.router, prefix="/v1", tags=["trials"])
api_router.include_router(results.router, prefix="/v1", tags=["results"])
