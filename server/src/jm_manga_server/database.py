import os
from pathlib import Path
from typing import Any

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel.ext.asyncio.session import AsyncSession

from jm_manga_server.config import Settings


def _make_engine(settings: Settings):
    return create_async_engine(
        f"sqlite+aiosqlite:///{settings.db_path}",
        echo=settings.env == "development",
        future=True,
    )


class _DatabaseState:
    def __init__(self) -> None:
        self.settings = Settings()
        self.engine = _make_engine(self.settings)
        self.session_maker = sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )

    def configure(self, settings: Settings) -> None:
        if settings.db_path == self.settings.db_path and settings.env == self.settings.env:
            self.settings = settings
            return
        self.settings = settings
        self.engine = _make_engine(settings)
        self.session_maker = sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )


_state = _DatabaseState()


class _AsyncEngineProxy:
    def begin(self):
        return _state.engine.begin()

    def __getattr__(self, name: str) -> Any:
        return getattr(_state.engine, name)


class _SessionMakerProxy:
    def __call__(self, *args, **kwargs):
        return _state.session_maker(*args, **kwargs)


async_engine = _AsyncEngineProxy()
async_session_maker = _SessionMakerProxy()


def configure_database(settings: Settings) -> None:
    """按启动配置设置数据库连接。保留 proxy 引用，避免导入方拿到旧对象。"""
    _state.configure(settings)


async def init_db(settings: Settings | None = None):
    """创建所有数据库表。"""
    from sqlmodel import SQLModel

    if settings is not None:
        configure_database(settings)

    async with async_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    # 限制数据库文件权限，避免其他本地用户读取账号凭据
    db_file = Path(_state.settings.db_path)
    if db_file.exists():
        os.chmod(db_file, 0o600)
