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
    instance_connection_name: str | None
    private_ip: bool


def _infer_instance_connection_name() -> str | None:
    project_id = os.getenv("FIREBASE_PROJECT_ID") or os.getenv("GCP_PROJECT")
    location = os.getenv("FIREBASE_SQL_LOCATION")
    instance_id = os.getenv("FIREBASE_SQL_INSTANCE_ID")
    if project_id and location and instance_id:
        return f"{project_id}:{location}:{instance_id}"
    return None


def get_database_config() -> DatabaseConfig:
    database_url = os.getenv("DATABASE_URL")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD") or os.getenv("DB_PASS")
    db_name = os.getenv("DB_NAME")
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT", "5432")
    db_sslmode = os.getenv("DB_SSLMODE", "require")
    instance_connection_name = (
        os.getenv("INSTANCE_CONNECTION_NAME")
        or os.getenv("CLOUD_SQL_CONNECTION_NAME")
        or _infer_instance_connection_name()
    )
    private_ip = os.getenv("PRIVATE_IP", "").strip().lower() in {"1", "true", "yes"}

    if database_url:
        return DatabaseConfig(
            database_url=database_url,
            db_user=db_user,
            db_password=db_password,
            db_name=db_name,
            db_host=db_host,
            db_port=db_port,
            db_sslmode=db_sslmode,
            instance_connection_name=instance_connection_name,
            private_ip=private_ip,
        )

    if instance_connection_name and all([db_user, db_password, db_name]):
        return DatabaseConfig(
            database_url=None,
            db_user=db_user,
            db_password=db_password,
            db_name=db_name,
            db_host=None,
            db_port=None,
            db_sslmode=None,
            instance_connection_name=instance_connection_name,
            private_ip=private_ip,
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
            instance_connection_name=None,
            private_ip=private_ip,
        )

    raise ValueError(
        "Database configuration is incomplete. Set DATABASE_URL, or set "
        "DB_USER/DB_PASSWORD/DB_NAME plus DB_HOST/DB_PORT, or set "
        "INSTANCE_CONNECTION_NAME (or FIREBASE_PROJECT_ID + FIREBASE_SQL_LOCATION + "
        "FIREBASE_SQL_INSTANCE_ID) with DB_USER/DB_PASSWORD/DB_NAME."
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
