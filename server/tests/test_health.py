from fastapi.testclient import TestClient

from jm_manga_server.main import app


def test_health_endpoint_returns_ok():
    """访问 /health 应返回 200 与状态信息。"""
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["version"] == "0.1.0"
    assert "uptime_seconds" in data
