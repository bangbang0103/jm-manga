from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, or_, select
from sqlmodel.ext.asyncio.session import AsyncSession

from jm_manga_server.dependencies import get_db_session, get_device_id, get_explicit_jm_user
from jm_manga_server.models import ReadingProgress, utc_now
from jm_manga_server.schemas import ApiResponse, ProgressPayload, ReadingProgressOut

router = APIRouter(prefix="/progress", tags=["progress"])


def _to_progress_out(progress: ReadingProgress) -> ReadingProgressOut:
    return ReadingProgressOut(
        album_id=progress.album_id,
        photo_id=progress.photo_id,
        title=progress.title,
        image_index=progress.image_index,
        is_finished=progress.is_finished,
        last_read_at=progress.last_read_at.isoformat(),
        episode_index=progress.episode_index,
        page_count=progress.page_count,
    )


def _is_better_progress(
    candidate: ReadingProgress,
    existing: ReadingProgress,
) -> bool:
    if candidate.last_read_at != existing.last_read_at:
        return candidate.last_read_at > existing.last_read_at
    return bool(candidate.jm_username) and not bool(existing.jm_username)


def _progress_owner_filter(jm_username: str, device_id: str):
    if jm_username:
        account_filter = ReadingProgress.jm_username == jm_username
        if device_id:
            return or_(
                account_filter,
                and_(
                    ReadingProgress.jm_username == "",
                    ReadingProgress.device_id == device_id,
                ),
            )
        return account_filter
    return and_(
        ReadingProgress.jm_username == "",
        ReadingProgress.device_id == device_id,
    )


@router.post("")
async def sync_progress(
    payload: ProgressPayload,
    jm_username: str = Depends(get_explicit_jm_user),
    device_id: str = Depends(get_device_id),
    session: AsyncSession = Depends(get_db_session),
):
    """同步某一章节的阅读进度。"""
    if jm_username:
        owner_filter = ReadingProgress.jm_username == jm_username
    else:
        owner_filter = and_(
            ReadingProgress.jm_username == "",
            ReadingProgress.device_id == device_id,
        )

    result = await session.execute(
        select(ReadingProgress).where(
            owner_filter,
            ReadingProgress.album_id == payload.album_id,
            ReadingProgress.photo_id == payload.photo_id,
        )
    )
    progress = result.scalar_one_or_none()

    if progress is None:
        progress = ReadingProgress(
            jm_username=jm_username,
            device_id=device_id,
            album_id=payload.album_id,
            photo_id=payload.photo_id,
            title=payload.title,
            image_index=payload.image_index,
            is_finished=payload.is_finished,
            episode_index=payload.episode_index,
            page_count=payload.page_count,
        )
        session.add(progress)
    else:
        progress.device_id = device_id
        progress.title = payload.title
        progress.image_index = payload.image_index
        progress.is_finished = payload.is_finished
        progress.episode_index = payload.episode_index
        progress.page_count = payload.page_count
        progress.last_read_at = utc_now()

    await session.commit()
    await session.refresh(progress)
    return ApiResponse(data=True)


@router.get("/recent")
async def get_recent_progress(
    limit: int = Query(20, ge=1, le=200),
    jm_username: str = Depends(get_explicit_jm_user),
    device_id: str = Depends(get_device_id),
    session: AsyncSession = Depends(get_db_session),
):
    """获取最近阅读的本子列表（每本子返回最新一章）。"""
    result = await session.execute(
        select(ReadingProgress).where(_progress_owner_filter(jm_username, device_id))
    )
    rows = result.scalars().all()

    latest_by_album: dict[str, ReadingProgress] = {}
    for row in rows:
        existing = latest_by_album.get(row.album_id)
        if existing is None or _is_better_progress(row, existing):
            latest_by_album[row.album_id] = row

    sorted_items = sorted(
        latest_by_album.values(),
        key=lambda p: p.last_read_at,
        reverse=True,
    )[:limit]

    items = [_to_progress_out(p) for p in sorted_items]
    return ApiResponse(data=items)


@router.get("/{album_id}")
async def get_progress(
    album_id: str,
    jm_username: str = Depends(get_explicit_jm_user),
    device_id: str = Depends(get_device_id),
    session: AsyncSession = Depends(get_db_session),
):
    """获取某本子的所有章节阅读进度。"""
    result = await session.execute(
        select(ReadingProgress)
        .where(
            _progress_owner_filter(jm_username, device_id),
            ReadingProgress.album_id == album_id,
        )
        .order_by(ReadingProgress.last_read_at.desc())
    )
    rows = result.scalars().all()

    latest_by_photo: dict[str, ReadingProgress] = {}
    for row in rows:
        existing = latest_by_photo.get(row.photo_id)
        if existing is None or _is_better_progress(row, existing):
            latest_by_photo[row.photo_id] = row

    items = [
        _to_progress_out(p)
        for p in sorted(
            latest_by_photo.values(),
            key=lambda progress: progress.last_read_at,
            reverse=True,
        )
    ]
    return ApiResponse(data=items)
