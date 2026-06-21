from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.main import app


def test_web_root_serves_index(tmp_path):
    (tmp_path / "index.html").write_text("<html>JM Web</html>", encoding="utf-8")
    app.state.settings = Settings(web_dir=str(tmp_path))

    response = TestClient(app).get("/")

    assert response.status_code == 200
    assert "JM Web" in response.text


def test_web_serves_static_assets(tmp_path):
    (tmp_path / "index.html").write_text("<html>JM Web</html>", encoding="utf-8")
    (tmp_path / "assets").mkdir()
    (tmp_path / "assets" / "app.txt").write_text("asset", encoding="utf-8")
    app.state.settings = Settings(web_dir=str(tmp_path))

    response = TestClient(app).get("/assets/app.txt")

    assert response.status_code == 200
    assert response.text == "asset"


def test_web_spa_route_falls_back_to_index(tmp_path):
    (tmp_path / "index.html").write_text("<html>JM Web</html>", encoding="utf-8")
    app.state.settings = Settings(web_dir=str(tmp_path))

    response = TestClient(app).get("/album/123")

    assert response.status_code == 200
    assert "JM Web" in response.text


def test_web_fallback_does_not_shadow_api_routes(tmp_path):
    (tmp_path / "index.html").write_text("<html>JM Web</html>", encoding="utf-8")
    app.state.settings = Settings(web_dir=str(tmp_path))

    response = TestClient(app).get("/api/v1/not-a-route")

    assert response.status_code == 404
