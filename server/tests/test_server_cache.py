from fastapi.testclient import TestClient

from jm_manga_server.config import Settings
from jm_manga_server.main import app


def test_cache_sizes_include_database_file_size(tmp_path):
    cache_dir = tmp_path / "cache"
    covers_dir = cache_dir / "covers"
    images_dir = cache_dir / "images"
    covers_dir.mkdir(parents=True)
    images_dir.mkdir(parents=True)
    (covers_dir / "cover.jpg").write_bytes(b"cover")
    (images_dir / "page.jpg").write_bytes(b"image-page")
    db_path = tmp_path / "app.db"
    db_path.write_bytes(b"sqlite-data")

    app.state.settings = Settings(cache_dir=str(cache_dir), db_path=str(db_path))

    response = TestClient(app).get("/api/v1/server/cache")

    assert response.status_code == 200
    assert response.json() == {
        "covers": 5,
        "images": 10,
        "database": 11,
    }
