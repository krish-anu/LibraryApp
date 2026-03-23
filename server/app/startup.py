from contextlib import asynccontextmanager

from fastapi import FastAPI

from .database import engine
from .models.base import Base

# Import models package so SQLAlchemy metadata is fully registered.
from . import models  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield
