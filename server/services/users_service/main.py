from app.app_factory import create_app
from app.routers import general, users

app = create_app(
    title="Library Users Service",
    routers=[general.router, users.router],
    serve_assets=False,
)
