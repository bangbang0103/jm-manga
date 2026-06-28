import pytest
from fastapi.testclient import TestClient

from jm_server.config import ServerConfig
from jm_server.main import create_app


class MockJmResp:
    """Mock response mimicking jmcomic's JmApiResp with pre-decrypted data."""

    def __init__(self, data, ts: str = "1234567890"):
        self._data = data
        self.ts = ts

    def json(self):
        return {"code": 200, "data": self._data}


class MockJmClient:
    def __init__(self):
        self.login_called = False
        self.api_request_calls = []
        self.scramble_html = '<script>var scramble_id = 12345;</script>'

    async def setup(self):
        pass

    async def close(self):
        pass

    async def api_request(self, method, path, params, data, cookie_header):
        self.api_request_calls.append((method, path, params, data, cookie_header))
        if path == "/album":
            return MockJmResp({"id": params.get("id"), "name": "Test Album"})
        if path == "/search":
            return MockJmResp({"total": 1, "content": []})
        return MockJmResp({})

    async def scramble_page(self, params, cookie_header):
        html = self.scramble_html
        if "imghost" not in html:
            html += "<script>const config = {imghost: 'https://cdn.example.com', cache: ''};</script>"
        return html

    async def login(self, username, password):
        self.login_called = True
        return {"s": "session-token", "username": username}, {"AVS": "session-token"}


@pytest.fixture
def test_client():
    app = create_app()
    app.state._injected_config = ServerConfig()
    app.state._injected_client = MockJmClient()
    with TestClient(app) as client:
        client.mock_client = app.state._injected_client
        yield client


def test_search_replays_and_reseals(test_client):
    response = test_client.get(
        "/search?search_query=test&page=1",
        headers={"tokenparam": "1234567890,1.7.0"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["code"] == 200
    assert "data" in body
    assert isinstance(body["data"], str)


def test_album_uses_cookie(test_client):
    response = test_client.get(
        "/album?id=123456",
        headers={
            "tokenparam": "1234567890,1.7.0",
            "Cookie": "AVS=my-session",
        },
    )
    assert response.status_code == 200
    call = test_client.mock_client.api_request_calls[-1]
    assert call[4] == "AVS=my-session"


def test_cache_uses_new_timestamp_on_hit(test_client):
    # First request encrypts with timestamp 1234567890.
    response1 = test_client.get(
        "/search?search_query=test&page=1",
        headers={"tokenparam": "1234567890,1.7.0"},
    )
    assert response1.status_code == 200
    assert response1.headers["X-JM-Timestamp"] == "1234567890"
    data1 = response1.json()["data"]

    # Second request with a different timestamp must re-encrypt the cached data.
    response2 = test_client.get(
        "/search?search_query=test&page=1",
        headers={"tokenparam": "9876543210,1.7.0"},
    )
    assert response2.status_code == 200
    assert response2.headers["X-JM-Timestamp"] == "9876543210"
    data2 = response2.json()["data"]

    # The encrypted payloads must differ because they use different timestamps.
    assert data1 != data2


def test_scramble_page_passthrough(test_client):
    response = test_client.get("/chapter_view_template?id=123&mode=vertical&page=0")
    assert response.status_code == 200
    assert "12345" in response.text
    assert "imghost: 'http://testserver'" in response.text
    assert "https://cdn.example.com" not in response.text


def test_scramble_page_public_base_url():
    app = create_app()
    app.state._injected_config = ServerConfig(public_base_url="https://jm.example.com/")
    app.state._injected_client = MockJmClient()
    with TestClient(app) as client:
        response = client.get("/chapter_view_template?id=123&mode=vertical&page=0")
    assert response.status_code == 200
    assert "imghost: 'https://jm.example.com'" in response.text


def test_scramble_page_x_forwarded_headers():
    app = create_app()
    app.state._injected_config = ServerConfig()
    app.state._injected_client = MockJmClient()
    with TestClient(app) as client:
        response = client.get(
            "/chapter_view_template?id=123&mode=vertical&page=0",
            headers={
                "X-Forwarded-Proto": "https",
                "X-Forwarded-Host": "proxy.example.com",
            },
        )
    assert response.status_code == 200
    assert "imghost: 'https://proxy.example.com'" in response.text


def test_scramble_page_forwarded_header():
    app = create_app()
    app.state._injected_config = ServerConfig()
    app.state._injected_client = MockJmClient()
    with TestClient(app) as client:
        response = client.get(
            "/chapter_view_template?id=123&mode=vertical&page=0",
            headers={"Forwarded": "for=192.0.2.1;host=rfc.example.com;proto=https"},
        )
    assert response.status_code == 200
    assert "imghost: 'https://rfc.example.com'" in response.text


def test_login_sets_cookie(test_client):
    response = test_client.post(
        "/login",
        data={"username": "user", "password": "pass"},
        headers={"tokenparam": "1234567890,1.7.0"},
    )
    assert response.status_code == 200
    assert "set-cookie" in response.headers
    assert test_client.mock_client.login_called is True
