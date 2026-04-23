from app.main import app


def test_release_configuration():
    """Check critical configuration for release readiness"""
    middleware_names = [m.cls.__name__ for m in app.user_middleware] # type: ignore
    assert "CORSMiddleware" in middleware_names
