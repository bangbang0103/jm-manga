import asyncio
import os
from pathlib import Path
from unittest.mock import MagicMock

import pytest
from sqlalchemy import delete

os.environ.setdefault("DB_PATH", "./data/app.db")
os.environ.setdefault("CACHE_DIR", "./data/cache")
os.environ.setdefault("MDNS_ENABLED", "false")

from jm_manga_server.database import async_engine, init_db
from jm_manga_server.main import app
from jm_manga_server.models import FavoriteCache, ReadingProgress


def _create_fake_jm_client():
    """创建一个非异步的 fake jm_client，避免同步方法被当作协程的警告。"""
    client = MagicMock()
    client.option.update_cookies = MagicMock()
    client._session.cookies.update = MagicMock()
    client._session.cookies.clear = MagicMock()
    return client


@pytest.fixture(autouse=True)
def ensure_app_state():
    """确保测试用的 app state 包含 jm_client、jm_lock 与并发控制信号量。"""
    app.state.jm_client = _create_fake_jm_client()
    app.state.jm_lock = asyncio.Lock()
    app.state.jm_semaphore = asyncio.Semaphore(5)
    app.state.image_semaphore = asyncio.Semaphore(3)
    app.state.image_write_locks = {}
    yield


@pytest.fixture(autouse=True)
async def ensure_db():
    """确保测试数据库目录与表结构存在，并清空测试数据。"""
    Path("./data").mkdir(parents=True, exist_ok=True)
    await init_db()

    async with async_engine.begin() as conn:
        await conn.execute(delete(ReadingProgress))
        await conn.execute(delete(FavoriteCache))

    yield
