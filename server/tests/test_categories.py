from unittest.mock import AsyncMock

from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.main import app


class FakeSearchPage:
    def __init__(self):
        self.content = [
            ("111", {"name": "Category Item", "tags": ["tag1"]}),
        ]
        self.total = 1
        self.page_size = 20


def test_categories_endpoint():
    """分类接口应返回结果。"""
    mock_client = AsyncMock()
    mock_client.categories_filter.return_value = FakeSearchPage()
    app.state.settings = Settings()
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.get("/api/v1/categories?page=1&category=0")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["total"] == 1
        assert len(data["items"]) == 1
    finally:
        app.dependency_overrides.clear()


def test_rankings_endpoint():
    """排行榜接口应返回结果。"""
    mock_client = AsyncMock()
    mock_client.week_ranking.return_value = FakeSearchPage()
    app.state.settings = Settings()
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.get("/api/v1/categories/rankings/weekly?page=1")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["total"] == 1
    finally:
        app.dependency_overrides.clear()


def _ranking_test(rank_type: str, method_name: str):
    mock_client = AsyncMock()
    getattr(mock_client, method_name).return_value = FakeSearchPage()
    app.state.settings = Settings()
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.get(f"/api/v1/categories/rankings/{rank_type}?page=1")
        assert response.status_code == 200
        getattr(mock_client, method_name).assert_awaited_once()
    finally:
        app.dependency_overrides.clear()


def test_rankings_daily():
    _ranking_test("daily", "day_ranking")


def test_rankings_weekly():
    _ranking_test("weekly", "week_ranking")


def test_rankings_monthly():
    _ranking_test("monthly", "month_ranking")


def test_invalid_rank_type_returns_422():
    """非法 rank_type 应返回 422。"""
    app.state.settings = Settings()
    client = TestClient(app)
    response = client.get("/api/v1/categories/rankings/yearly?page=1")
    assert response.status_code == 422


def test_invalid_page_returns_422():
    """page 小于 1 应返回 422。"""
    app.state.settings = Settings()
    client = TestClient(app)
    response = client.get("/api/v1/categories?page=0")
    assert response.status_code == 422
