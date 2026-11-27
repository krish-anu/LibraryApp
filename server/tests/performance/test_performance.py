import pytest
import time
from fastapi.testclient import TestClient


def test_book_search_performance(
    client: TestClient, override_auth_dependency, auth_headers
):
    """PERF-01: Book search under load"""
    # Ideally use a profiler or run many times
    start_time = time.time()
    for _ in range(50):
        response = client.get("/books?search=test", headers=auth_headers)
        assert response.status_code == 200
    duration = time.time() - start_time

    # Assert average time is under threshold (e.g. 10ms per req => 0.5s total)
    # Be generous for CI environments
    assert duration < 5.0


def test_pagination_performance(
    client: TestClient, override_auth_dependency, auth_headers
):
    """PERF-02: Pagination performance"""
    # Request deep page
    start_time = time.time()
    response = client.get("/books?page=100&limit=10", headers=auth_headers)
    duration = time.time() - start_time

    assert response.status_code == 200
    assert duration < 0.5
