import asyncio
import logging
import time
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from jmcomic.jm_exception import ResponseUnexpectedException
from sqlalchemy import delete, select
from sqlmodel.ext.asyncio.session import AsyncSession

from jm_manga_server.cookies import try_jm_relogin
from jm_manga_server.dependencies import (
    get_db_session,
    get_jm_client,
    prepare_jm_account,
)
from jm_manga_server.models import FavoriteCache
from jm_manga_server.schemas import (
    ApiResponse,
    FavoriteStatus,
    SearchItem,
    SearchResult,
)

router = APIRouter(prefix="/favorites", tags=["favorites"])
logger = logging.getLogger(__name__)

_THROTTLE_SECONDS = 180
_AUTO_SYNC_THROTTLE_SECONDS = 300

# 按 JM 用户名隔离的同步时间戳与锁，避免多用户共享节流窗口及并发重复同步。
_last_sync: dict[str, float] = {}
_last_auto_sync: dict[str, float] = {}
_sync_locks: dict[str, asyncio.Lock] = {}


def _sync_lock(username: str) -> asyncio.Lock:
    if username not in _sync_locks:
        _sync_locks[username] = asyncio.Lock()
    return _sync_locks[username]


def _is_login_required_error(exc: Exception) -> bool:
    """判断 JM 异常是否因为未登录/会话过期。"""
    msg = str(exc)
    return '"code":401' in msg or "请先登入会员" in msg or "Please login" in msg


async def _album_status_with_relogin(
    client,
    jm_username: str,
    album_id: str,
    encryption_key: str | None = None,
):
    """查询本子收藏状态，401 时尝试用本地密码重登一次再重试。"""
    try:
        resp = await client.req_api("/album", params={"id": album_id})
    except ResponseUnexpectedException as e:
        if not jm_username or not _is_login_required_error(e):
            raise
        logger.info("JM session expired for %s, trying relogin", jm_username)
        if not await try_jm_relogin(client, jm_username, encryption_key):
            raise
        resp = await client.req_api("/album", params={"id": album_id})

    return bool(resp.res_data.get("is_favorite", False))


async def _toggle_favorite_with_relogin(
    client,
    jm_username: str,
    album_id: str,
    encryption_key: str | None = None,
):
    """切换收藏状态，401 时尝试用本地密码重登一次再重试。"""
    try:
        resp = await client.req_api(
            "/favorite",
            get=False,
            require_success=False,
            data={"aid": album_id},
        )
    except ResponseUnexpectedException as e:
        if not jm_username or not _is_login_required_error(e):
            raise
        logger.info("JM session expired for %s, trying relogin", jm_username)
        if not await try_jm_relogin(client, jm_username, encryption_key):
            raise
        resp = await client.req_api(
            "/favorite",
            get=False,
            require_success=False,
            data={"aid": album_id},
        )

    return resp


async def _favorite_folder_with_relogin(
    client,
    jm_username: str,
    page: int,
    folder_id: str,
    encryption_key: str | None = None,
):
    """调用 client.favorite_folder，401 时尝试用本地密码重登一次再重试。"""
    try:
        return await client.favorite_folder(page=page, folder_id=folder_id)
    except ResponseUnexpectedException as e:
        if not jm_username or not _is_login_required_error(e):
            raise
        logger.info("JM session expired for %s, trying relogin", jm_username)
        if not await try_jm_relogin(client, jm_username, encryption_key):
            raise
        return await client.favorite_folder(page=page, folder_id=folder_id)


async def sync_favorites_folder(
    client,
    session: AsyncSession,
    folder_id: str = "0",
    force: bool = False,
    jm_username: str = "",
    encryption_key: str | None = None,
):
    """登录后自动全量同步官方收藏夹。force 为 true 时忽略 5 分钟频率限制。"""
    lock = _sync_lock(jm_username)
    async with lock:
        now = time.time()
        if not force and now - _last_auto_sync.get(jm_username, 0) < _AUTO_SYNC_THROTTLE_SECONDS:
            return {"synced": False, "reason": "throttled"}

        if not getattr(client, "login", None):
            raise HTTPException(status_code=503, detail="JM client does not support login")

        logger.info(
            "Start full sync favorites for folder_id=%s jm_username=%s",
            folder_id,
            jm_username,
        )
        await session.execute(
            delete(FavoriteCache).where(
                FavoriteCache.jm_username == jm_username,
                FavoriteCache.folder_id == folder_id,
            )
        )

        # 先取第 1 页，同时拿到总页数，避免无上限递增 page
        first_page = await _favorite_folder_with_relogin(
            client, jm_username, page=1, folder_id=folder_id, encryption_key=encryption_key
        )
        total_pages = getattr(first_page, "page_count", None) or 1
        logger.info("favorite_folder total_pages=%s", total_pages)
        total = 0

        for page in range(1, total_pages + 1):
            folder_page = (
                first_page
                if page == 1
                else await _favorite_folder_with_relogin(
                    client,
                    jm_username,
                    page=page,
                    folder_id=folder_id,
                    encryption_key=encryption_key,
                )
            )
            if not folder_page.content:
                logger.info("favorite_folder page=%s empty, stop sync", page)
                break
            logger.info("favorite_folder page=%s count=%s", page, len(folder_page.content))
            for album_id, data in folder_page.content:
                result = await session.execute(
                    select(FavoriteCache).where(
                        FavoriteCache.jm_username == jm_username,
                        FavoriteCache.album_id == album_id,
                        FavoriteCache.folder_id == folder_id,
                    )
                )
                fav = result.scalars().first()
                if fav is None:
                    fav = FavoriteCache(
                        jm_username=jm_username,
                        album_id=album_id,
                        folder_id=folder_id,
                    )
                fav.title = data.get("name", "")
                fav.folder_name = "Default"
                fav.page = page
                fav.cached_at = datetime.now(timezone.utc)
                session.add(fav)
            total += len(folder_page.content)

        await session.commit()
        _last_auto_sync[jm_username] = now
        logger.info("Full sync favorites done, total=%s", total)
        return {"synced": True, "count": total, "pages": total_pages}


@router.get("")
async def get_favorites(
    folder_id: str = Query("0"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=1000),
    jm_username: str = Depends(prepare_jm_account),
    session: AsyncSession = Depends(get_db_session),
):
    """获取收藏夹缓存分页（按缓存行 LIMIT/OFFSET）。"""
    total_result = await session.execute(
        select(FavoriteCache).where(
            FavoriteCache.jm_username == jm_username,
            FavoriteCache.folder_id == folder_id,
        )
    )
    total = len(total_result.scalars().all())

    result = await session.execute(
        select(FavoriteCache)
        .where(
            FavoriteCache.jm_username == jm_username,
            FavoriteCache.folder_id == folder_id,
        )
        .order_by(FavoriteCache.page.asc(), FavoriteCache.id.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    rows = result.scalars().all()
    logger.info(
        "get_favorites folder_id=%s jm_username=%s page=%s page_size=%s returned %s/%s rows",
        folder_id,
        jm_username,
        page,
        page_size,
        len(rows),
        total,
    )

    items = [SearchItem(album_id=f.album_id, title=f.title, tags=[]) for f in rows]
    return ApiResponse(
        data=SearchResult(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
        )
    )


@router.post("/sync")
async def sync_favorites(
    request: Request,
    folder_id: str = Query("0"),
    page: int = Query(1, ge=1),
    force: bool = Query(False),
    full: bool = Query(False),
    jm_username: str = Depends(prepare_jm_account),
    client=Depends(get_jm_client),
    session: AsyncSession = Depends(get_db_session),
):
    """手动同步官方收藏夹。force=true 时忽略 3 分钟节流，full=true 时全量同步所有页。"""
    encryption_key = request.app.state.settings.jm_password_encryption_key

    if full:
        result = await sync_favorites_folder(
            client,
            session,
            folder_id=folder_id,
            force=force,
            jm_username=jm_username,
            encryption_key=encryption_key,
        )
        return ApiResponse(data=result)

    lock = _sync_lock(jm_username)
    async with lock:
        now = time.time()
        if not force and now - _last_sync.get(jm_username, 0) < _THROTTLE_SECONDS:
            return ApiResponse(data={"synced": False, "reason": "throttled"})

        if not getattr(client, "login", None):
            raise HTTPException(status_code=503, detail="JM client does not support login")

        folder_page = await _favorite_folder_with_relogin(
            client,
            jm_username,
            page=page,
            folder_id=folder_id,
            encryption_key=encryption_key,
        )
        _last_sync[jm_username] = now

        if force and page == 1:
            await session.execute(
                delete(FavoriteCache).where(
                    FavoriteCache.jm_username == jm_username,
                    FavoriteCache.folder_id == folder_id,
                )
            )

        for album_id, data in folder_page.content:
            existing = await session.execute(
                select(FavoriteCache).where(
                    FavoriteCache.jm_username == jm_username,
                    FavoriteCache.album_id == album_id,
                    FavoriteCache.folder_id == folder_id,
                )
            )
            fav = existing.scalar_one_or_none()
            if fav is None:
                fav = FavoriteCache(
                    jm_username=jm_username,
                    album_id=album_id,
                    folder_id=folder_id,
                )
            fav.title = data.get("name", "")
            fav.folder_name = "Default"
            fav.page = page
            fav.cached_at = datetime.now(timezone.utc)
            session.add(fav)

        await session.commit()
        return ApiResponse(data={"synced": True, "count": len(folder_page.content), "page": page})


@router.get("/{album_id}")
async def get_favorite_status(
    request: Request,
    album_id: str,
    jm_username: str = Depends(prepare_jm_account),
    client=Depends(get_jm_client),
):
    """查询单本子的官方收藏状态。需要已登录 JM 账号。"""
    if not jm_username:
        raise HTTPException(status_code=401, detail="JM login required")

    encryption_key = request.app.state.settings.jm_password_encryption_key
    favorited = await _album_status_with_relogin(
        client, jm_username, album_id, encryption_key=encryption_key
    )
    return ApiResponse(data=FavoriteStatus(favorited=favorited))


@router.post("/{album_id}")
async def toggle_favorite(
    request: Request,
    album_id: str,
    jm_username: str = Depends(prepare_jm_account),
    client=Depends(get_jm_client),
    session: AsyncSession = Depends(get_db_session),
):
    """切换官方收藏状态并同步本地缓存。需要已登录 JM 账号。"""
    if not jm_username:
        raise HTTPException(status_code=401, detail="JM login required")
    if not getattr(client, "login", None):
        raise HTTPException(status_code=503, detail="JM client does not support login")

    encryption_key = request.app.state.settings.jm_password_encryption_key
    try:
        resp = await _toggle_favorite_with_relogin(
            client, jm_username, album_id, encryption_key=encryption_key
        )
    except HTTPException:
        raise
    except ResponseUnexpectedException as e:
        if _is_login_required_error(e):
            logger.warning("JM favorite toggle login expired for %s", jm_username)
            raise HTTPException(status_code=401, detail="JM login expired or not logged in") from e
        logger.warning(
            "JM favorite request failed for user %s album %s: %s",
            jm_username,
            album_id,
            e,
        )
        raise HTTPException(status_code=502, detail="JM favorite request failed") from e
    except Exception as e:
        logger.warning(
            "JM favorite request failed for user %s album %s: %s",
            jm_username,
            album_id,
            e,
        )
        raise HTTPException(status_code=502, detail="JM favorite request failed") from e

    res_data = getattr(resp, "res_data", None) or {}
    if res_data.get("status") != "ok":
        logger.warning(
            "JM favorite failed for user %s album %s: %s",
            jm_username,
            album_id,
            res_data,
        )
        raise HTTPException(status_code=502, detail="JM favorite failed")

    favorited = await _album_status_with_relogin(
        client, jm_username, album_id, encryption_key=encryption_key
    )

    if favorited:
        title = ""
        try:
            album = await client.get_album_detail(album_id)
            title = album.name
        except Exception:
            pass
        result = await session.execute(
            select(FavoriteCache).where(
                FavoriteCache.jm_username == jm_username,
                FavoriteCache.album_id == album_id,
                FavoriteCache.folder_id == "0",
            )
        )
        fav = result.scalar_one_or_none()
        if fav is None:
            fav = FavoriteCache(
                jm_username=jm_username,
                album_id=album_id,
                folder_id="0",
            )
        fav.title = title
        fav.folder_name = "Default"
        fav.page = 1
        fav.cached_at = datetime.now(timezone.utc)
        session.add(fav)
    else:
        await session.execute(
            delete(FavoriteCache).where(
                FavoriteCache.jm_username == jm_username,
                FavoriteCache.album_id == album_id,
                FavoriteCache.folder_id == "0",
            )
        )
    await session.commit()

    return ApiResponse(data=FavoriteStatus(favorited=favorited))
