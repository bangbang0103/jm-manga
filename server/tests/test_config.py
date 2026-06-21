import os
from pathlib import Path

from jm_manga_server.config import Settings


def test_settings_loads_from_env():
    """配置应从环境变量读取。"""
    env = {
        "API_TOKEN": "test_token",
        "HOST": "127.0.0.1",
        "PORT": "9000",
        "ENV": "production",
        "DB_PATH": "$HOME/.jm-manga/custom.db",
        "CACHE_DIR": "$HOME/.jm-manga/custom-cache",
    }
    for key, value in env.items():
        os.environ[key] = value

    try:
        settings = Settings()
        assert settings.api_token == "test_token"
        assert settings.host == "127.0.0.1"
        assert settings.port == 9000
        assert settings.env == "production"
        assert settings.db_path == str(Path.home() / ".jm-manga" / "custom.db")
        assert settings.cache_dir == str(Path.home() / ".jm-manga" / "custom-cache")
    finally:
        for key in env:
            os.environ.pop(key, None)


def test_settings_has_sensible_defaults():
    """未提供环境变量时应有合理默认值。"""
    # 确保相关环境变量不存在
    for key in ["API_TOKEN", "HOST", "PORT", "ENV", "DB_PATH", "CACHE_DIR"]:
        os.environ.pop(key, None)

    settings = Settings()
    assert settings.host == "0.0.0.0"
    assert settings.port == 8000
    assert settings.env == "development"
    assert settings.api_token is None
    assert settings.db_path == str(Path.home() / ".jm-manga" / "app.db")
    assert settings.cache_dir == str(Path.home() / ".jm-manga" / "cache")
