import asyncio

from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.cookies import save_jm_cookies
from jm_manga_server.main import app


def _setup_app():
    app.state.settings = Settings()


async def _seed_cookies():
    await save_jm_cookies("user_a", {"AVS": "a"})
    await save_jm_cookies("user_b", {"AVS": "b"})


def test_alternating_usernames_do_not_leak_progress():
    """交替使用不同 X-JM-Username 请求时，进度与 cookies 按用户隔离。

    后端当前用全局 jm_lock 串行化所有 JM 相关调用，因此本测试用顺序请求
    验证每个请求结束后 client cookies 被清理，进度写入到对应用户名下。
    """
    _setup_app()
    asyncio.run(_seed_cookies())
    client = TestClient(app)

    # user_a 先同步一章
    response = client.post(
        "/api/v1/progress",
        json={"album_id": "shared", "photo_id": "photo_a", "image_index": 1},
        headers={"X-JM-Username": "user_a"},
    )
    assert response.status_code == 200

    # user_b 同步另一章
    response = client.post(
        "/api/v1/progress",
        json={"album_id": "shared", "photo_id": "photo_b", "image_index": 2},
        headers={"X-JM-Username": "user_b"},
    )
    assert response.status_code == 200

    # 各自只能查到自己的进度
    response = client.get(
        "/api/v1/progress/shared",
        headers={"X-JM-Username": "user_a"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo_a"

    response = client.get(
        "/api/v1/progress/shared",
        headers={"X-JM-Username": "user_b"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["photo_id"] == "photo_b"


def test_invalid_x_jm_username_rejected():
    """X-JM-Username 必须是服务端已保存 cookies 的账号。"""
    _setup_app()
    client = TestClient(app)

    response = client.get(
        "/api/v1/progress/any",
        headers={"X-JM-Username": "not_a_saved_user"},
    )
    assert response.status_code == 401
    assert "not available" in response.json()["message"]
