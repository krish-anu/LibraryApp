from __future__ import annotations

import atexit

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .db_config import build_host_database_url, get_database_config


config = get_database_config()
_connector = None

if config.database_url:
    engine = create_engine(
        config.database_url,
        echo=False,
        pool_pre_ping=True,
        pool_recycle=1800,
    )
elif config.instance_connection_name:
    from google.cloud.sql.connector import Connector, IPTypes

    _connector = Connector(refresh_strategy="LAZY")
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

