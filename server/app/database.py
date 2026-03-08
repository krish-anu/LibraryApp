from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os
from pathlib import Path
from urllib.parse import quote_plus

# Load .env explicitly from server/.env
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")


if not all([DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME]):
    raise ValueError("One or more database environment variables are missing!")

encoded_user = quote_plus(str(DB_USER))
encoded_password = quote_plus(str(DB_PASSWORD))

DATABASE_URL = (
    f"postgresql+psycopg2://{encoded_user}:{encoded_password}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}?sslmode=require"
)

engine = create_engine(
    DATABASE_URL,
    echo=False,  # Disable SQL logging in production to prevent data leakage
    pool_size=10,
    max_overflow=20,
    pool_timeout=30,
    pool_recycle=1800,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
