from __future__ import annotations

import os
from dataclasses import dataclass
from urllib.parse import quote_plus

from .env import load_app_env


load_app_env()


@dataclass(frozen=True)
class DatabaseConfig:
    database_url: str | None
    db_user: str | None
    db_password: str | None
    db_name: str | None
    db_host: str | None
    db_port: str | None
    db_sslmode: str | None


def get_database_config() -> DatabaseConfig:
    database_url = os.getenv("DATABASE_URL")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD") or os.getenv("DB_PASS")
    db_name = os.getenv("DB_NAME")
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT", "5432")
    db_sslmode = os.getenv("DB_SSLMODE", "disable")

    if database_url:
        return DatabaseConfig(
            database_url=database_url,
            db_user=db_user,
            db_password=db_password,
            db_name=db_name,
            db_host=db_host,
            db_port=db_port,
            db_sslmode=db_sslmode,
        )

    if all([db_user, db_password, db_host, db_port, db_name]):
        return DatabaseConfig(
            database_url=None,
            db_user=db_user,
            db_password=db_password,
            db_name=db_name,
            db_host=db_host,
            db_port=db_port,
            db_sslmode=db_sslmode,
        )

    raise ValueError(
        "Database configuration is incomplete. Set DATABASE_URL, or set "
        "DB_USER/DB_PASSWORD/DB_NAME plus DB_HOST/DB_PORT."
    )


def build_host_database_url(config: DatabaseConfig) -> str:
    if not all([config.db_user, config.db_password, config.db_host, config.db_port, config.db_name]):
        raise ValueError("Host-based database configuration is incomplete.")

    encoded_user = quote_plus(str(config.db_user))
    encoded_password = quote_plus(str(config.db_password))
    url = (
        f"postgresql+psycopg2://{encoded_user}:{encoded_password}"
        f"@{config.db_host}:{config.db_port}/{config.db_name}"
    )
    if config.db_sslmode:
        url = f"{url}?sslmode={config.db_sslmode}"
    return url
