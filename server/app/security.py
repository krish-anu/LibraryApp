import ipaddress
import os
from typing import Iterable

from fastapi import Request
from slowapi import Limiter


def env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def env_int(name: str, default: int, minimum: int) -> int:
    raw = os.getenv(name)
    if raw is None:
        return default

    try:
        value = int(raw)
    except ValueError as exc:
        raise ValueError(f"{name} must be an integer") from exc

    if value < minimum:
        raise ValueError(f"{name} must be >= {minimum}")

    return value


def parse_allowed_origins() -> list[str]:
    raw = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
    origins = [origin.strip() for origin in raw.split(",") if origin.strip()]
    allow_credentials = env_bool("CORS_ALLOW_CREDENTIALS", True)

    if allow_credentials and "*" in origins:
        raise ValueError(
            "ALLOWED_ORIGINS cannot contain '*' when CORS_ALLOW_CREDENTIALS is true"
        )

    if not origins:
        raise ValueError("ALLOWED_ORIGINS cannot be empty")

    return origins


def _parse_trusted_proxy_networks() -> list[ipaddress._BaseNetwork]:
    raw = os.getenv("TRUSTED_PROXY_CIDRS", "")
    networks: list[ipaddress._BaseNetwork] = []

    for token in [part.strip() for part in raw.split(",") if part.strip()]:
        try:
            if "/" in token:
                networks.append(ipaddress.ip_network(token, strict=False))
            else:
                addr = ipaddress.ip_address(token)
                networks.append(
                    ipaddress.ip_network(f"{addr}/{32 if addr.version == 4 else 128}")
                )
        except ValueError as exc:
            raise ValueError(f"Invalid TRUSTED_PROXY_CIDRS entry: {token}") from exc

    return networks


def _is_trusted_proxy(request: Request) -> bool:
    if not env_bool("TRUST_PROXY_HEADERS", False):
        return False

    if not request.client or not request.client.host:
        return False

    networks = _parse_trusted_proxy_networks()
    if not networks:
        return False

    try:
        client_ip = ipaddress.ip_address(request.client.host)
    except ValueError:
        return False

    return any(client_ip in network for network in networks)


def client_identifier(request: Request) -> str:
    if _is_trusted_proxy(request):
        x_forwarded_for = request.headers.get("x-forwarded-for")
        if x_forwarded_for:
            first = x_forwarded_for.split(",")[0].strip()
            if first:
                return first

        x_real_ip = request.headers.get("x-real-ip")
        if x_real_ip:
            real = x_real_ip.strip()
            if real:
                return real

    if request.client and request.client.host:
        return request.client.host

    return "unknown"


def create_limiter(default_limits: Iterable[str] | None = None) -> Limiter:
    return Limiter(
        key_func=client_identifier, default_limits=list(default_limits or [])
    )
