from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv


SERVER_ROOT = Path(__file__).resolve().parent.parent


def resolve_env_file() -> Path:
    configured = os.getenv("SERVER_ENV_FILE") or os.getenv("ENV_FILE")
    if configured:
        env_path = Path(configured)
        return env_path if env_path.is_absolute() else SERVER_ROOT / env_path

    for candidate in (".env.local", ".env.production"):
        env_path = SERVER_ROOT / candidate
        if env_path.exists():
            return env_path

    return SERVER_ROOT / ".env.local"


def load_app_env() -> Path:
    env_path = resolve_env_file()
    load_dotenv(env_path)
    return env_path
