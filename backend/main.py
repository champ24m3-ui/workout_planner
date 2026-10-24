"""Run from the project root: python -m uvicorn backend.main:app."""

from contextlib import asynccontextmanager
from typing import Literal

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from starlette.concurrency import run_in_threadpool

from backend.config import Settings
from backend.database import create_database_engine
from backend.profile import router as profile_router


class HealthResponse(BaseModel):
    status: Literal["ok", "error"]


class DatabaseHealthResponse(HealthResponse):
    database: Literal["connected", "unavailable"]


def create_app() -> FastAPI:
    @asynccontextmanager
    async def lifespan(application: FastAPI):
        # Fail startup clearly for missing configuration. Connections are lazy,
        # allowing liveness to work while MySQL is temporarily unavailable.
        engine = create_database_engine(Settings.load())
        application.state.database_engine = engine
        try:
            yield
        finally:
            await run_in_threadpool(engine.dispose)

    application = FastAPI(title="Smart Workout Planner", lifespan=lifespan)
    application.include_router(profile_router)

    @application.get("/health", response_model=HealthResponse)
    def health():
        return {"status": "ok"}

    @application.get(
        "/health/db",
        response_model=DatabaseHealthResponse,
        responses={503: {"model": DatabaseHealthResponse}},
    )
    def database_health(request: Request):
        try:
            with request.app.state.database_engine.connect() as connection:
                connection.execute(text("SELECT 1")).scalar_one()
        except SQLAlchemyError:
            # Never return or log the driver exception: it can contain credentials.
            return JSONResponse(
                status_code=503,
                content={"status": "error", "database": "unavailable"},
            )
        return {"status": "ok", "database": "connected"}

    return application


app = create_app()
