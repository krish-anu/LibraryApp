from contextlib import asynccontextmanager
from fastapi import FastAPI
from .database import engine
from .models.base import Base
from .routers import books, loans, general,category


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="Library App API", lifespan=lifespan)

app.include_router(general.router)
app.include_router(books.router)
app.include_router(loans.router)
app.include_router(category.router)
