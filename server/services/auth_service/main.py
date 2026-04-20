from app.app_factory import create_app
from app.routers import auth, general

app = create_app(
    title="Library Auth Service",
    routers=[general.router, auth.router],
    serve_assets=False,
)
