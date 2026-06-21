import pytest
from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession

from jm_manga_server.models import FavoriteCache, ReadingProgress


@pytest.fixture
async def async_engine():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
async def async_session(async_engine):
    async with AsyncSession(async_engine) as session:
        yield session


async def test_reading_progress_crud(async_session: AsyncSession):
    """阅读进度模型可正常增删改查。"""
    progress = ReadingProgress(
        album_id="12345",
        photo_id="67890",
        image_index=5,
        is_finished=False,
    )
    async_session.add(progress)
    await async_session.commit()
    await async_session.refresh(progress)

    assert progress.id is not None
    assert progress.album_id == "12345"
    assert progress.image_index == 5


async def test_favorite_cache_crud(async_session: AsyncSession):
    """收藏夹缓存模型可正常增删改查。"""
    fav = FavoriteCache(
        album_id="11111",
        title="Test Album",
        folder_id="0",
        folder_name="Default",
    )
    async_session.add(fav)
    await async_session.commit()
    await async_session.refresh(fav)

    assert fav.id is not None
    assert fav.title == "Test Album"
