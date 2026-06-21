from unittest.mock import AsyncMock

from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.main import app


class FakeAlbumDetail:
    def __init__(self):
        self.album_id = "12345"
        self.name = "Test Album"
        self.description = "A test description"
        self.author = "Test Author"
        self.tags = ["action", "fantasy"]
        self.likes = "1K"
        self.views = "10K"
        self.episode_list = [
            ("67890", "1", "Chapter 1"),
            ("67891", "2", "Chapter 2"),
        ]


class FakeAlbumRaw:
    def __init__(self):
        self.res_data = {"is_favorite": False}


class FakePhotoDetail:
    def __init__(self):
        self.photo_id = "67890"
        self.name = "Chapter 1"
        self.from_album = FakeAlbumDetail()
        self.page_arr = ["1.jpg", "2.jpg"]


def test_album_detail_endpoint():
    """本子详情接口应返回详情。"""
    mock_client = AsyncMock()
    mock_client.get_album_detail.return_value = FakeAlbumDetail()
    mock_client.req_api.return_value = FakeAlbumRaw()
    app.state.settings = Settings()
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.get("/api/v1/albums/12345")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["album_id"] == "12345"
        assert data["title"] == "Test Album"
        assert len(data["episodes"]) == 2
    finally:
        app.dependency_overrides.clear()


def test_photo_detail_endpoint():
    """章节详情接口应返回详情。"""
    mock_client = AsyncMock()
    mock_client.get_photo_detail.return_value = FakePhotoDetail()
    app.state.settings = Settings()
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        response = client.get("/api/v1/albums/photos/67890")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["photo_id"] == "67890"
        assert data["page_count"] == 2
    finally:
        app.dependency_overrides.clear()
