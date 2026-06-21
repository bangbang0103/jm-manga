from fastapi import APIRouter, Depends, Query, Request

from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.schemas import ApiResponse, SearchItem, SearchResult

router = APIRouter(prefix="/search", tags=["search"])


def _cover_url(request: Request, album_id: str, size: str = "") -> str:
    suffix = f"?size={size}" if size else ""
    return f"{request.base_url}api/v1/covers/{album_id}{suffix}"


@router.get("")
async def search(
    request: Request,
    q: str = Query(..., min_length=1, description="搜索关键词"),
    page: int = Query(1, ge=1, description="页码"),
    client=Depends(get_jm_client),
):
    """站内搜索。"""
    async with request.app.state.jm_semaphore:
        result = await client.search_site(search_query=q, page=page)
    items = [
        SearchItem(
            album_id=album_id,
            title=data.get("name", ""),
            tags=data.get("tags", []),
            cover_url=_cover_url(request, album_id, size="_3x4"),
        )
        for album_id, data in result.content
    ]
    return ApiResponse(
        data=SearchResult(
            items=items,
            total=result.total,
            page=page,
            page_size=getattr(result, "page_size", 20),
        )
    )


@router.get("/tag")
async def search_tag(
    request: Request,
    tag: str = Query(..., min_length=1, description="标签"),
    page: int = Query(1, ge=1, description="页码"),
    client=Depends(get_jm_client),
):
    """标签搜索。"""
    async with request.app.state.jm_semaphore:
        result = await client.search_tag(search_query=tag, page=page)
    items = [
        SearchItem(
            album_id=album_id,
            title=data.get("name", ""),
            tags=data.get("tags", []),
            cover_url=_cover_url(request, album_id, size="_3x4"),
        )
        for album_id, data in result.content
    ]
    return ApiResponse(
        data=SearchResult(
            items=items,
            total=result.total,
            page=page,
            page_size=getattr(result, "page_size", 20),
        )
    )
