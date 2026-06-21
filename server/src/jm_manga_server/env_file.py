from pathlib import Path
from secrets import token_urlsafe


def _secret() -> str:
    return token_urlsafe(32)


def build_env_file() -> str:
    """生成适合首次部署的 .env 内容。"""
    return "\n".join(
        [
            "# JM",
            f"JM_PASSWORD_ENCRYPTION_KEY={_secret()}",
            "CLIENT_IMPL=api",
            "JM_DOMAIN_LIST=",
            "PROXY=",
            "",
            "# Service",
            f"API_TOKEN={_secret()}",
            "HOST=127.0.0.1",
            "PORT=8000",
            "ENV=production",
            "LOG_LEVEL=INFO",
            "NETWORK_MODE=public",
            "MDNS_ENABLED=false",
            "ENABLE_METRICS=false",
            "",
            "# Storage",
            "DB_PATH=$HOME/.jm-manga/app.db",
            "CACHE_DIR=$HOME/.jm-manga/cache",
            "",
            "# Concurrency",
            "JM_CONCURRENCY=5",
            "IMAGE_CONCURRENCY=3",
            "",
            "# Image signing",
            "IMAGE_TOKEN_TTL=3600",
            f"IMAGE_SIGN_SECRET={_secret()}",
            "",
        ]
    )


def write_env_file(path: str | Path = ".env", *, force: bool = False) -> Path:
    """写入新的 .env 文件，默认不覆盖已有文件。"""
    env_path = Path(path)
    if env_path.exists() and not force:
        raise FileExistsError(f"{env_path} already exists; pass --force to overwrite it")

    env_path.parent.mkdir(parents=True, exist_ok=True)
    env_path.write_text(build_env_file(), encoding="utf-8")
    env_path.chmod(0o600)
    return env_path
