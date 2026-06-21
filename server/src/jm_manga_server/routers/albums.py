import logging
from typing import Any

from fastapi import APIRouter, Depends, Path, Request
from jmcomic.jm_exception import ResponseUnexpectedException

from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.routers.favorites import _is_login_required_error
from jm_manga_server.routers.images import generate_image_token
from jm_manga_server.schemas import AlbumDetail, ApiResponse, PhotoDetail

router = APIRouter(prefix="/albums", tags=["albums"])
logger = logging.getLogger(__name__)


@router.get("/{album_id}")
async def album_detail(
    request: Request,
    album_id: str = Path(...),
    client=Depends(get_jm_client),
):
    """本子详情。"""
    async with request.app.state.jm_semaphore:
        album = await client.get_album_detail(album_id)

    episodes: list[dict[str, Any]] = [
        {
            "photo_id": photo_id,
            "index": int(photo_index),
            "title": photo_title,
        }
        for photo_id, photo_index, photo_title in album.episode_list
    ]

    is_favorite = False
    try:
        async with request.app.state.jm_semaphore:
            raw = await client.req_api("/album", params={"id": album_id})
        is_favorite = bool(raw.res_data.get("is_favorite", False))
    except ResponseUnexpectedException as e:
        if _is_login_required_error(e):
            logger.debug("Album favorite check skipped: JM login required")
        else:
            logger.warning("Album favorite check failed: %s", e)
    except Exception as e:  # noqa: BLE001
        logger.warning("Album favorite check failed: %s", e)

    return ApiResponse(
        data=AlbumDetail(
            album_id=album.album_id,
            title=album.name,
            description=album.description,
            author=album.author,
            tags=album.tags,
            cover_url=f"{request.base_url}api/v1/covers/{album.album_id}",
            likes=album.likes,
            views=album.views,
            episodes=episodes,
            is_favorite=is_favorite,
        )
    )


@router.get("/photos/{photo_id}")
async def photo_detail(
    request: Request,
    photo_id: str = Path(...),
    client=Depends(get_jm_client),
):
    """章节详情。"""
    async with request.app.state.jm_semaphore:
        photo = await client.get_photo_detail(photo_id)
    settings = request.app.state.settings
    secret = settings.image_sign_secret or settings.api_token or ""
    ttl = settings.image_token_ttl

    page_count = len(photo.page_arr) if photo.page_arr else 0
    image_urls = [
        (
            f"/api/v1/images/{photo.photo_id}/{index}"
            f"?token={generate_image_token(photo.photo_id, index, ttl, secret)}"
        )
        for index in range(page_count)
    ]

    return ApiResponse(
        data=PhotoDetail(
            photo_id=photo.photo_id,
            title=photo.name,
            album_id=photo.from_album.album_id if photo.from_album else "",
            page_count=page_count,
            image_urls=image_urls,
        )
    )
