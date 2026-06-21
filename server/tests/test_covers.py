from unittest.mock import AsyncMock

from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.main import app


class FakeImage:
    def __init__(self):
        self.content = b"fake-cover-bytes"


class FakeJmcomicText:
    @staticmethod
    def get_album_cover_url(album_id: str, size: str = "") -> str:
        return f"https://cdn.example.com/covers/{album_id}/{size}"


def _setup_app(tmp_path, api_token: str | None = "secret"):
    app.state.settings = Settings(
        api_token=api_token,
        cache_dir=str(tmp_path / "cache"),
    )
    mock_client = AsyncMock()
    mock_client.get_jm_image.return_value = FakeImage()
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client
    return mock_client


def test_cover_requires_auth(tmp_path):
    """未提供鉴权时 /covers 应返回 401。"""
    _setup_app(tmp_path, api_token="secret")

    try:
        client = TestClient(app)
        response = client.get("/api/v1/covers/12345")
        assert response.status_code == 401
    finally:
        app.dependency_overrides.clear()


def test_cover_allows_auth(tmp_path):
    """提供正确鉴权时 /covers 应返回封面内容。"""
    _setup_app(tmp_path, api_token="secret")

    try:
        client = TestClient(app)
        response = client.get(
            "/api/v1/covers/12345",
            headers={"Authorization": "Bearer secret"},
        )
        assert response.status_code == 200
        assert response.content == b"fake-cover-bytes"
    finally:
        app.dependency_overrides.clear()


def test_cover_rejects_invalid_size(tmp_path):
    """非法 size 参数应返回 400。"""
    _setup_app(tmp_path, api_token="secret")

    try:
        client = TestClient(app)
        response = client.get(
            "/api/v1/covers/12345?size=../../etc/passwd",
            headers={"Authorization": "Bearer secret"},
        )
        assert response.status_code == 400
    finally:
        app.dependency_overrides.clear()


def test_cover_rejects_path_traversal(tmp_path):
    """size 参数导致缓存路径穿越时应返回 400。"""
    _setup_app(tmp_path, api_token="secret")

    try:
        client = TestClient(app)
        response = client.get(
            "/api/v1/covers/12345?size=/../../../foo",
            headers={"Authorization": "Bearer secret"},
        )
        assert response.status_code == 400
    finally:
        app.dependency_overrides.clear()
