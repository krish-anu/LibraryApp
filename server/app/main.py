from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from .database import engine
from .models.base import Base

# Import models package to ensure all model modules are loaded and registered with SQLAlchemy
from . import models  # noqa: F401
from .routers import books, loans, general, category, favorites, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="Library App API", lifespan=lifespan)

# Serve client assets (book covers etc.) at /assets
project_root = Path(__file__).resolve().parents[1].parent
client_assets = project_root / "client" / "assets"
if client_assets.exists():
    app.mount("/assets", StaticFiles(directory=str(client_assets)), name="assets")

app.include_router(general.router)
app.include_router(books.router)
app.include_router(loans.router)
app.include_router(category.router)
app.include_router(favorites.router)
app.include_router(users.router)
