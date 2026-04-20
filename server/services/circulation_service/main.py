from app.app_factory import create_app
from app.routers import favorites, general, loans, reservations

app = create_app(
    title="Library Circulation Service",
    routers=[general.router, loans.router, reservations.router, favorites.router],
    serve_assets=False,
)
