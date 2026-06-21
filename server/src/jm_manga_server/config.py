import os
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def _default_data_dir() -> Path:
    return Path.home() / ".jm-manga"


def _default_db_path() -> str:
    return str(_default_data_dir() / "app.db")


def _default_cache_dir() -> str:
    return str(_default_data_dir() / "cache")


class Settings(BaseSettings):
    """应用配置，环境变量优先。"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # JM
    jm_password_encryption_key: str | None = None
    client_impl: str = "api"  # api 或 html
    jm_domain_list: str = ""
    proxy: str | None = None

    # 服务
    api_token: str | None = None
    host: str = "0.0.0.0"
    port: int = 8000
    env: str = "development"  # development 或 production
    log_level: str = "INFO"
    network_mode: str = "auto"  # lan, public, auto
    mdns_enabled: bool = True
    enable_metrics: bool = False
    web_dir: str = "./web"

    # 存储
    db_path: str = Field(default_factory=_default_db_path)
    cache_dir: str = Field(default_factory=_default_cache_dir)

    @field_validator("db_path", "cache_dir", mode="before")
    @classmethod
    def expand_storage_path(cls, value: str) -> str:
        return os.path.expanduser(os.path.expandvars(value))

    # 并发
    jm_concurrency: int = 5
    image_concurrency: int = 3

    # 图片签名
    image_token_ttl: int = 3600
    image_sign_secret: str | None = None
