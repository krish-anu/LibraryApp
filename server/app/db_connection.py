from __future__ import annotations

import atexit
import json
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .db_config import build_host_database_url, get_database_config


config = get_database_config()
_connector = None


def _google_credentials():
    raw_service_account = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if raw_service_account:
        from google.oauth2 import service_account

        return service_account.Credentials.from_service_account_info(
            json.loads(raw_service_account)
        )

    service_account_file = (
        os.getenv("FIREBASE_SERVICE_ACCOUNT_FILE")
        or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        or ""
    ).strip()
    if service_account_file:
        from google.oauth2 import service_account

        return service_account.Credentials.from_service_account_file(
            service_account_file
        )

    return None

if config.database_url:
    engine = create_engine(
        config.database_url,
        echo=False,
        pool_pre_ping=True,
        pool_recycle=1800,
    )
elif config.instance_connection_name:
    from google.cloud.sql.connector import Connector, IPTypes

    _connector = Connector(
        credentials=_google_credentials(),
        refresh_strategy="LAZY",
    )
    atexit.register(_connector.close)
    ip_type = IPTypes.PRIVATE if config.private_ip else IPTypes.PUBLIC

    def getconn():
        return _connector.connect(
            config.instance_connection_name,
            "pg8000",
            user=config.db_user,
            password=config.db_password,
            db=config.db_name,
            ip_type=ip_type,
        )

    engine = create_engine(
        "postgresql+pg8000://",
        creator=getconn,
        echo=False,
        pool_pre_ping=True,
        pool_recycle=1800,
    )
else:
    engine = create_engine(
        build_host_database_url(config),
        echo=False,
        pool_pre_ping=True,
        pool_recycle=1800,
    )


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
