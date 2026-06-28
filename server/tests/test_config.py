from pathlib import Path

import pytest
import yaml

from jm_server.config import ServerConfig, load_config


def test_default_config():
    config = ServerConfig()
    assert config.host == "0.0.0.0"
    assert config.port == 8080
    assert config.api_cache_ttl == 60
    assert config.image_cache_max_gb == 50


def test_config_from_yaml(tmp_path, monkeypatch):
    config_file = tmp_path / "config.yml"
    config_file.write_text(
        yaml.safe_dump(
            {
                "host": "127.0.0.1",
                "port": 9000,
                "image_cache_max_gb": 100,
            }
        ),
        encoding="utf-8",
    )
    config = load_config(config_file)
    assert config.host == "127.0.0.1"
    assert config.port == 9000
    assert config.image_cache_max_gb == 100


def test_env_override(monkeypatch):
    monkeypatch.setenv("JM_SERVER_HOST", "127.0.0.1")
    monkeypatch.setenv("JM_SERVER_PORT", "9000")
    monkeypatch.setenv("JM_SERVER_IMAGE_CACHE_MAX_GB", "100")
    monkeypatch.setenv("JM_SERVER_JM_LOG_ENABLED", "true")
    monkeypatch.setenv("JM_SERVER_PUBLIC_BASE_URL", "https://jm.example.com")
    config = load_config()
    assert config.host == "127.0.0.1"
    assert config.port == 9000
    assert config.image_cache_max_gb == 100
    assert config.jm_log_enabled is True
    assert config.public_base_url == "https://jm.example.com"
