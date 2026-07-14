import pytest
from fastapi import HTTPException

from app.services.images import validate_image_body


def test_image_validation_rejects_plain_text_as_png():
    with pytest.raises(HTTPException) as exc_info:
        validate_image_body(b"plain text", "image/png")

    assert exc_info.value.status_code == 415
