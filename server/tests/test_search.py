from unittest.mock import AsyncMock

import pytest
from fastapi.testclient import TestClient

from jm_manga_server.main import app


class FakeSearchPage:
    def __init__(self):
        self.content = [
            ("12345", {"name": "Test Album", "tags": ["action", "fantasy"]}),
            ("67890", {"name": "Another Album", "tags": ["romance"]}),
        ]
        self.total = 2
        self.page_size = 20


@pytest.fixture
def mock_client():
    """构造一个模拟的 jmcomic 异步客户端。"""
    client = AsyncMock()
    client.search_site.return_value = FakeSearchPage()
    return client


def test_search_endpoint_returns_results(mock_client):
    """搜索接口应返回结果列表。"""
    from jm_manga_server.config import Settings

    app.state.settings = Settings()
    app.dependency_overrides[get_jm_client] = lambda: mock_client
    try:
        test_client = TestClient(app)
        response = test_client.get("/api/v1/search?q=test&page=1")
        assert response.status_code == 200
        data = response.json()
        payload = data["data"]
        assert payload["total"] == 2
        assert len(payload["items"]) == 2
        assert payload["items"][0]["album_id"] == "12345"
        assert payload["items"][0]["title"] == "Test Album"
    finally:
        app.dependency_overrides.clear()


# 延迟导入以避免循环依赖
from jm_manga_server.dependencies import get_jm_client  # noqa: E402
