from fastapi import APIRouter, Depends, HTTPException, Query, Request

from jm_manga_server.dependencies import get_jm_client
from jm_manga_server.schemas import ApiResponse, SearchItem, SearchResult

router = APIRouter(prefix="/categories", tags=["categories"])


def _cover_url(request: Request, album_id: str, size: str = "") -> str:
    suffix = f"?size={size}" if size else ""
    return f"{request.base_url}api/v1/covers/{album_id}{suffix}"


@router.get("")
async def categories(
    request: Request,
    page: int = Query(1, ge=1),
    time: str = Query("a", min_length=1, max_length=1),
    category: str = Query("0", min_length=1, max_length=20),
    order_by: str = Query("mr", min_length=1, max_length=10),
    sub_category: str | None = Query(None, min_length=1, max_length=20),
    client=Depends(get_jm_client),
):
    """分类浏览。"""
    async with request.app.state.jm_semaphore:
        result = await client.categories_filter(
            page=page,
            time=time,
            category=category,
            order_by=order_by,
            sub_category=sub_category,
        )
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


@router.get("/rankings/{rank_type}")
async def rankings(
    request: Request,
    rank_type: str,
    page: int = Query(1, ge=1),
    category: str = Query("0"),
    client=Depends(get_jm_client),
):
    """排行榜：daily / weekly / monthly。"""
    method_map = {
        "daily": "day_ranking",
        "weekly": "week_ranking",
        "monthly": "month_ranking",
    }
    method_name = method_map.get(rank_type)
    if method_name is None or not hasattr(client, method_name):
        raise HTTPException(status_code=422, detail=f"Unsupported rank type: {rank_type}")

    method = getattr(client, method_name)
    async with request.app.state.jm_semaphore:
        result = await method(page=page, category=category)
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
