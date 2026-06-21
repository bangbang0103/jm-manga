import asyncio
import os
from unittest.mock import AsyncMock

import httpx
import pytest
from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.main import app
from jm_manga_server.routers.images import generate_image_token


class FakeImageResp:
    def __init__(self, content: bytes):
        self.content = content

    def transfer_to(self, path, scramble_id=None):
        with open(path, "wb") as f:
            f.write(self.content)


class FakePhotoDetail:
    def __init__(self):
        self.page_arr = ["1.jpg"]
        self.photo_id = "photo_1"
        self.scramble_id = ""

    def get_img_data_original(self, img_name: str) -> str:
        return f"https://cdn.example.com/media/photos/{self.photo_id}/{img_name}"


def test_image_proxy_returns_cached_image(tmp_path):
    """图片代理应校验签名并返回图片。"""
    image_data = b"fake-image-bytes"

    mock_client = AsyncMock()
    mock_client.get_photo_detail.return_value = FakePhotoDetail()
    mock_client.get_jm_image.return_value = FakeImageResp(image_data)

    app.state.settings = Settings(
        api_token="secret",
        cache_dir=str(tmp_path / "cache"),
    )
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    try:
        client = TestClient(app)
        token = generate_image_token("photo_1", 0, 3600, "secret")
        response = client.get("/api/v1/images/photo_1/0?token=" + token)
        assert response.status_code == 200
        assert response.content == image_data

        # 第二次请求应直接走缓存
        response2 = client.get("/api/v1/images/photo_1/0?token=" + token)
        assert response2.status_code == 200
    finally:
        app.dependency_overrides.clear()
        os.environ.pop("CACHE_DIR", None)


@pytest.mark.asyncio
async def test_concurrent_image_requests_return_complete_bytes(tmp_path):
    """并发请求同一张图片时，最终都应返回完整数据，不能读到半写文件。"""
    image_data = b"fake-image-bytes-for-concurrency-test"

    class SlowImageResp:
        def transfer_to(self, path, scramble_id=None):
            import time

            time.sleep(0.1)
            with open(path, "wb") as f:
                f.write(image_data)

    mock_client = AsyncMock()
    mock_client.get_photo_detail.return_value = FakePhotoDetail()
    mock_client.get_jm_image.return_value = SlowImageResp()
    app.state.settings = Settings(
        api_token="secret",
        cache_dir=str(tmp_path / "cache"),
    )
    app.state.jm_client = mock_client
    app.dependency_overrides[get_jm_client] = lambda: mock_client

    token = generate_image_token("photo_1", 0, 3600, "secret")
    try:
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
            responses = await asyncio.gather(
                client.get(f"/api/v1/images/photo_1/0?token={token}"),
                client.get(f"/api/v1/images/photo_1/0?token={token}"),
            )
        for response in responses:
            assert response.status_code == 200
            assert response.content == image_data
    finally:
        app.dependency_overrides.clear()
