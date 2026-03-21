import os
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv


env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)


def _build_database_url() -> str:
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT")
    db_name = os.getenv("DB_NAME")
    db_sslmode = os.getenv("DB_SSLMODE", "require")
    database_url = os.getenv("DATABASE_URL")

    if not database_url and not all([db_user, db_password, db_host, db_port, db_name]):
        raise ValueError(
            "DATABASE_URL or the split DB_* environment variables are required."
        )

    if database_url:
        return database_url

    encoded_user = quote_plus(str(db_user))
    encoded_password = quote_plus(str(db_password))
    url = (
        f"postgresql+psycopg2://{encoded_user}:{encoded_password}"
        f"@{db_host}:{db_port}/{db_name}"
    )
    if db_sslmode:
        url = f"{url}?sslmode={db_sslmode}"
    return url


DATABASE_URL = _build_database_url()
