from fastapi import APIRouter

from app.api.v1 import candidates, health, results, sessions, trials, known_animals, training_sessions, training_data, models, countries, tts, joke, heatmap

api_router = APIRouter()
api_router.include_router(health.router, prefix="/v1", tags=["health"])
api_router.include_router(sessions.router, prefix="/v1", tags=["sessions"])
api_router.include_router(candidates.router, prefix="/v1", tags=["candidates"])
api_router.include_router(trials.router, prefix="/v1", tags=["trials"])
api_router.include_router(results.router, prefix="/v1", tags=["results"])
api_router.include_router(known_animals.router, prefix="/v1", tags=["known-animals"])
api_router.include_router(training_sessions.router, prefix="/v1", tags=["training-sessions"])
api_router.include_router(training_data.router, prefix="/v1", tags=["training-data"])
api_router.include_router(models.router, prefix="/v1", tags=["models"])
api_router.include_router(countries.router, prefix="/v1", tags=["countries"])
api_router.include_router(tts.router, prefix="/v1", tags=["tts"])
api_router.include_router(joke.router, prefix="/v1", tags=["joke"])
api_router.include_router(heatmap.router, prefix="/v1", tags=["heatmap"])


