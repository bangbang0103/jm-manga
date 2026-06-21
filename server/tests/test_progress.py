import asyncio

from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.cookies import save_jm_cookies
from jm_manga_server.main import app


def _setup_app():
    app.state.settings = Settings()


async def _seed_users(users: list[str]):
    for user in users:
        await save_jm_cookies(user, {"AVS": "test"})


def test_sync_and_get_progress():
    """阅读进度可同步并查询。"""
    _setup_app()
    client = TestClient(app)

    # 同步进度
    response = client.post(
        "/api/v1/progress",
        json={"album_id": "12345", "photo_id": "67890", "image_index": 5},
    )
    assert response.status_code == 200
    assert response.json()["data"] is True

    # 查询进度，现在返回章节列表
    response = client.get("/api/v1/progress/12345")
    assert response.status_code == 200
    data = response.json()["data"]
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]["album_id"] == "12345"
    assert data[0]["photo_id"] == "67890"
    assert data[0]["image_index"] == 5


def test_get_recent_progress():
    """可获取最近阅读列表。"""
    _setup_app()
    client = TestClient(app)

    client.post(
        "/api/v1/progress",
        json={"album_id": "11111", "photo_id": "22222", "image_index": 1},
    )

    response = client.get("/api/v1/progress/recent")
    assert response.status_code == 200
    data = response.json()["data"]
    assert isinstance(data, list)
    assert len(data) >= 1


def test_progress_isolated_by_jm_username():
    """阅读进度按 X-JM-Username 隔离。"""
    _setup_app()
    asyncio.run(_seed_users(["user_a", "user_b"]))
    client = TestClient(app)

    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo1", "image_index": 1},
        headers={"X-JM-Username": "user_a"},
    )
    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo2", "image_index": 2},
        headers={"X-JM-Username": "user_b"},
    )

    response = client.get(
        "/api/v1/progress/album1",
        headers={"X-JM-Username": "user_a"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo1"

    response = client.get(
        "/api/v1/progress/album1",
        headers={"X-JM-Username": "user_b"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo2"


def test_anonymous_progress_isolated_by_device_id():
    """匿名阅读进度按 X-Device-Id 隔离。"""
    _setup_app()
    client = TestClient(app)

    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo1", "image_index": 1},
        headers={"X-Device-Id": "device_a"},
    )
    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo2", "image_index": 2},
        headers={"X-Device-Id": "device_b"},
    )

    response = client.get(
        "/api/v1/progress/album1",
        headers={"X-Device-Id": "device_a"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo1"

    response = client.get(
        "/api/v1/progress/album1",
        headers={"X-Device-Id": "device_b"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo2"


def test_logged_in_progress_does_not_match_other_account_on_same_device():
    """同一设备切换账号时，不应按 device_id 泄露其它账号的阅读记录。"""
    _setup_app()
    asyncio.run(_seed_users(["user_a", "user_b"]))
    client = TestClient(app)

    client.post(
        "/api/v1/progress",
        json={"album_id": "shared", "photo_id": "photo_a", "image_index": 1},
        headers={"X-JM-Username": "user_a", "X-Device-Id": "device_1"},
    )
    client.post(
        "/api/v1/progress",
        json={"album_id": "shared", "photo_id": "photo_b", "image_index": 2},
        headers={"X-JM-Username": "user_b", "X-Device-Id": "device_1"},
    )

    response = client.get(
        "/api/v1/progress/shared",
        headers={"X-JM-Username": "user_a", "X-Device-Id": "device_1"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo_a"


def test_logged_in_progress_includes_current_device_anonymous_progress():
    """登录后查询包含当前设备匿名记录，并与账号记录按章节去重。"""
    _setup_app()
    asyncio.run(_seed_users(["user_a"]))
    client = TestClient(app)

    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo1", "image_index": 1},
        headers={"X-Device-Id": "device_1"},
    )
    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo2", "image_index": 2},
        headers={"X-JM-Username": "user_a", "X-Device-Id": "device_1"},
    )
    client.post(
        "/api/v1/progress",
        json={"album_id": "album1", "photo_id": "photo2", "image_index": 3},
        headers={"X-Device-Id": "device_1"},
    )

    response = client.get(
        "/api/v1/progress/album1",
        headers={"X-JM-Username": "user_a", "X-Device-Id": "device_1"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert {item["photo_id"] for item in data} == {"photo1", "photo2"}
    photo2 = next(item for item in data if item["photo_id"] == "photo2")
    assert photo2["image_index"] == 3


def test_get_progress_empty_returns_empty_list():
    """未阅读过某本子时返回 200 + 空数组，而非 404。"""
    _setup_app()
    client = TestClient(app)

    response = client.get("/api/v1/progress/unknown-album")
    assert response.status_code == 200
    assert response.json()["data"] == []
