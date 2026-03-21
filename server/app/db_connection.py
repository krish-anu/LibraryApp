from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .db_config import DATABASE_URL


engine = create_engine(
    DATABASE_URL,
    echo=False,  # Disable SQL logging in production to prevent data leakage
    pool_size=10,
    max_overflow=20,
    pool_timeout=30,
    pool_recycle=1800,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
