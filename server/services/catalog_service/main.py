from app.app_factory import create_app
from app.routers import books, category, general

app = create_app(
    title="Library Catalog Service",
    routers=[general.router, books.router, category.router],
    serve_assets=False,
)
