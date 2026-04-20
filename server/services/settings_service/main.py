from app.app_factory import create_app
from app.routers import general, settings

app = create_app(
    title="Library Settings Service",
    routers=[general.router, settings.router],
    serve_assets=False,
)
