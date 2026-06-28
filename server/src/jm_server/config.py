"""Configuration loading for jm-manga-server."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class ServerConfig:
    """Runtime configuration for the server."""

    host: str = "0.0.0.0"
    port: int = 8080
    log_level: str = "INFO"
    log_file: str | None = None
    log_max_bytes: int = 10 * 1024 * 1024  # 10 MB
    log_backup_count: int = 5

    api_cache_ttl: int = 60  # seconds
    api_cache_size: int = 1000  # max entries in memory

    image_cache_dir: Path = field(default_factory=lambda: Path("./cache/images"))
    image_cache_max_gb: int = 50

    jm_option_file: Path | None = None
    jm_log_enabled: bool = False

    # Public base URL used when rewriting image host references (e.g. behind a reverse proxy).
    # If unset, the server falls back to X-Forwarded-* / Forwarded headers, then the request URL.
    public_base_url: str | None = None

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "ServerConfig":
        """Build a config from a dictionary, applying type coercion."""
        converted: dict[str, Any] = {}

        if "image_cache_dir" in data:
            converted["image_cache_dir"] = Path(data["image_cache_dir"])
        if "jm_option_file" in data:
            value = data["jm_option_file"]
            converted["jm_option_file"] = Path(value) if value else None

        for key in (
            "host",
            "port",
            "log_level",
            "log_file",
            "log_max_bytes",
            "log_backup_count",
            "api_cache_ttl",
            "api_cache_size",
            "image_cache_max_gb",
            "jm_log_enabled",
            "public_base_url",
        ):
            if key in data:
                converted[key] = data[key]

        return cls(**converted)


def _env_overrides() -> dict[str, Any]:
    """Return overrides from environment variables."""
    overrides: dict[str, Any] = {}
    mapping = {
        "JM_SERVER_HOST": "host",
        "JM_SERVER_PORT": ("port", int),
        "JM_SERVER_LOG_LEVEL": "log_level",
        "JM_SERVER_LOG_FILE": "log_file",
        "JM_SERVER_LOG_MAX_BYTES": ("log_max_bytes", int),
        "JM_SERVER_LOG_BACKUP_COUNT": ("log_backup_count", int),
        "JM_SERVER_API_CACHE_TTL": ("api_cache_ttl", int),
        "JM_SERVER_API_CACHE_SIZE": ("api_cache_size", int),
        "JM_SERVER_IMAGE_CACHE_DIR": "image_cache_dir",
        "JM_SERVER_IMAGE_CACHE_MAX_GB": ("image_cache_max_gb", int),
        "JM_SERVER_JM_OPTION_FILE": "jm_option_file",
        "JM_SERVER_JM_LOG_ENABLED": ("jm_log_enabled", lambda v: v.lower() in ("1", "true", "yes")),
        "JM_SERVER_PUBLIC_BASE_URL": "public_base_url",
    }

    for env_name, target in mapping.items():
        value = os.environ.get(env_name)
        if value is None:
            continue
        if isinstance(target, tuple):
            key, converter = target
            overrides[key] = converter(value)
        else:
            overrides[target] = value

    return overrides


def load_config(config_path: str | Path | None = None) -> ServerConfig:
    """Load server configuration.

    Priority:
        1. Default values
        2. YAML config file (if provided or found at default paths)
        3. Environment variables
    """
    data: dict[str, Any] = {}

    if config_path is not None:
        path = Path(config_path)
        if path.exists():
            with path.open("r", encoding="utf-8") as f:
                data = yaml.safe_load(f) or {}
    else:
        for candidate in (Path("config.yml"), Path("config.yaml")):
            if candidate.exists():
                with candidate.open("r", encoding="utf-8") as f:
                    data = yaml.safe_load(f) or {}
                break

    data.update(_env_overrides())
    return ServerConfig.from_dict(data)
