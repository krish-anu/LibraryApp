from fastapi import HTTPException, status
from fastapi.responses import Response


MAX_IMAGE_BYTES = 10 * 1024 * 1024
ALLOWED_IMAGE_MIME_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}


def _has_allowed_magic_bytes(body: bytes, mime_type: str) -> bool:
    if mime_type == "image/jpeg":
        return len(body) >= 3 and body[:3] == b"\xff\xd8\xff"
    if mime_type == "image/png":
        return len(body) >= 8 and body[:8] == b"\x89PNG\r\n\x1a\n"
    if mime_type == "image/gif":
        return len(body) >= 4 and body[:4] == b"GIF8"
    if mime_type == "image/webp":
        return len(body) >= 12 and body[:4] == b"RIFF" and body[8:12] == b"WEBP"
    return False


def validate_image_body(body: bytes, content_type: str | None) -> tuple[bytes, str]:
    mime_type = (content_type or "").split(";", 1)[0].lower()
    if mime_type not in ALLOWED_IMAGE_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Image must be JPEG, PNG, WebP, or GIF",
        )

    if not body:
        raise HTTPException(status_code=400, detail="Image body is required")
    if len(body) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image is too large")
    if not _has_allowed_magic_bytes(body, mime_type):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Image bytes do not match the Content-Type",
        )

    return body, mime_type


def image_response(body: bytes | memoryview, mime_type: str | None) -> Response:
    return Response(
        content=bytes(body),
        media_type=mime_type or "application/octet-stream",
        headers={"Cache-Control": "public, max-age=3600"},
    )
