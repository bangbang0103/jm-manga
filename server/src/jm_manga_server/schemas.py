from typing import Any, Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """统一 API 响应结构。"""

    code: str = "OK"
    message: str = "success"
    data: T | None = None


class SearchItem(BaseModel):
    """搜索/分类/排行列表项。"""

    album_id: str
    title: str
    tags: list[str]
    cover_url: str | None = None


class SearchResult(BaseModel):
    """搜索结果。"""

    items: list[SearchItem]
    total: int
    page: int
    page_size: int


class AlbumDetail(BaseModel):
    """本子详情。"""

    album_id: str
    title: str
    description: str
    author: str
    tags: list[str]
    cover_url: str | None = None
    likes: str | None = None
    views: str | None = None
    episodes: list[dict[str, Any]]
    is_favorite: bool = False


class FavoriteStatus(BaseModel):
    """单本子收藏状态。"""

    favorited: bool


class PhotoDetail(BaseModel):
    """章节详情。"""

    photo_id: str
    title: str
    album_id: str
    page_count: int
    image_urls: list[str]


class ProgressPayload(BaseModel):
    """阅读进度提交载荷。"""

    album_id: str
    photo_id: str
    title: str | None = None
    image_index: int
    is_finished: bool = False
    episode_index: int | None = None
    page_count: int | None = None


class ReadingProgressOut(BaseModel):
    """阅读进度输出。"""

    album_id: str
    photo_id: str
    title: str | None = None
    image_index: int
    is_finished: bool
    last_read_at: str
    episode_index: int | None = None
    page_count: int | None = None


class FavoriteItem(BaseModel):
    """收藏夹项。"""

    album_id: str
    title: str
    folder_id: str
    folder_name: str
