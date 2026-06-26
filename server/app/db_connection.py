from __future__ import annotations

import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .db_config import build_host_database_url, get_database_config


config = get_database_config()

if config.database_url:
    engine = create_engine(
        config.database_url,
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
