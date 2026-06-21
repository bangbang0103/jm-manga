from unittest.mock import AsyncMock

import pytest
from fastapi.testclient import TestClient
from jmcomic.jm_exception import ResponseUnexpectedException

from jm_manga_server.config import Settings
from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.main import app


@pytest.fixture(autouse=True)
def _reset_favorites_sync_state():
    """每个测试前清空收藏夹同步节流状态，避免测试互相影响。"""
    from jm_manga_server.routers import favorites

    favorites._last_sync.clear()
    favorites._last_auto_sync.clear()
    favorites._sync_locks.clear()
    yield
    favorites._last_sync.clear()
    favorites._last_auto_sync.clear()
    favorites._sync_locks.clear()


class FakeFavoritePage:
    def __init__(self):
        self.content = [
            ("12345", {"name": "Favorite One"}),
            ("67890", {"name": "Favorite Two"}),
        ]
        self.total = 2


def test_get_favorites_returns_cache():
    """收藏夹接口应返回缓存数据。"""
    app.state.settings = Settings()
    client = TestClient(app)

    response = client.get("/api/v1/favorites?folder_id=0")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["total"] == 0
    assert data["items"] == []


def test_sync_favorites_with_mock():
    """同步收藏夹应写入缓存。"""
    mock_client = AsyncMock()
    mock_client.favorite_folder.return_value = FakeFavoritePage()
    app.state.settings = Settings()
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.post("/api/v1/favorites/sync?folder_id=0")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["synced"] is True
        assert data["count"] == 2

        # 再次获取收藏夹应看到缓存
        response = client.get("/api/v1/favorites?folder_id=0")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["total"] == 2
    finally:
        app.dependency_overrides.clear()


def test_toggle_favorite_returns_401_when_jm_session_expired():
    """JM 会话过期且本地没有可重登密码时，toggle 返回 401。"""
    mock_client = AsyncMock()
    mock_client.req_api.side_effect = ResponseUnexpectedException(
        '{"code":401,"message":"Unauthorized"}',
        context={},
    )
    mock_client.login = True
    app.state.settings = Settings()
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.post("/api/v1/favorites/12345")
        assert response.status_code == 401
        assert "login" in response.json()["message"].lower()
    finally:
        app.dependency_overrides.clear()


def test_sync_favorites_throttled_without_force():
    """短时间内重复同步应被节流。"""
    mock_client = AsyncMock()
    mock_client.favorite_folder.return_value = FakeFavoritePage()
    app.state.settings = Settings()
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.post("/api/v1/favorites/sync?folder_id=0")
        assert response.status_code == 200
        assert response.json()["data"]["synced"] is True

        response = client.post("/api/v1/favorites/sync?folder_id=0")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["synced"] is False
        assert data["reason"] == "throttled"
    finally:
        app.dependency_overrides.clear()
