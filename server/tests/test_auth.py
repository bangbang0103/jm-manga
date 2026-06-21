import os
from unittest.mock import AsyncMock

from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.main import app


def _setup_app():
    app.state.settings = Settings()
    app.state.jm_client = AsyncMock()


def test_api_token_required_when_configured():
    """配置 API_TOKEN 后未提供 Bearer Token 应返回 401。"""
    _setup_app()
    app.state.settings = Settings(api_token="secret123")
    client = TestClient(app)

    response = client.get("/api/v1/search?q=test")
    assert response.status_code == 401


def test_api_token_allows_valid_bearer():
    """提供正确的 Bearer Token 应通过认证。"""
    _setup_app()
    app.state.settings = Settings(api_token="secret123")
    client = TestClient(app)

    response = client.get(
        "/api/v1/search?q=test",
        headers={"Authorization": "Bearer secret123"},
    )
    # 无真实 JM 客户端，认证通过后会因 mock 返回而 200
    assert response.status_code == 200


def test_no_token_required_when_not_configured():
    """未配置 API_TOKEN 时不校验认证。"""
    _setup_app()
    os.environ.pop("API_TOKEN", None)
    app.state.settings = Settings()
    client = TestClient(app)

    response = client.get("/api/v1/search?q=test")
    assert response.status_code == 200


def test_jm_test_login_without_saving():
    """/auth/test 仅验证登录，不保存 cookies。"""
    _setup_app()
    mock_login = AsyncMock(return_value=None)
    app.state.jm_client.login = mock_login
    client = TestClient(app)

    response = client.post(
        "/api/v1/auth/test",
        json={"username": "tester", "password": "pass"},
    )
    assert response.status_code == 200
    assert response.json()["username"] == "tester"
    mock_login.assert_awaited_once()
