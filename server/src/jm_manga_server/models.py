from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Index, text
from sqlmodel import Field, SQLModel


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class ReadingProgress(SQLModel, table=True):
    """阅读进度表。

    登录记录按 JM 账号隔离；匿名记录按 device_id 隔离。
    """

    __tablename__ = "reading_progress"

    id: Optional[int] = Field(default=None, primary_key=True)
    jm_username: str = Field(default="", index=True)
    device_id: str = Field(default="", index=True)
    album_id: str = Field(index=True)
    photo_id: str
    title: Optional[str] = None
    image_index: int = 0
    last_read_at: datetime = Field(default_factory=utc_now)
    is_finished: bool = False
    episode_index: Optional[int] = Field(default=None)
    page_count: Optional[int] = Field(default=None)

    __table_args__ = (
        Index(
            "ix_reading_progress_user_album_photo",
            "jm_username",
            "album_id",
            "photo_id",
            unique=True,
            sqlite_where=text("jm_username != ''"),
        ),
        Index(
            "ix_reading_progress_device_album_photo",
            "device_id",
            "album_id",
            "photo_id",
            unique=True,
            sqlite_where=text("jm_username = ''"),
        ),
    )


class FavoriteCache(SQLModel, table=True):
    """官方收藏夹缓存表。按 jm_username 隔离。"""

    __tablename__ = "favorite_cache"

    id: Optional[int] = Field(default=None, primary_key=True)
    jm_username: str = Field(default="", index=True)
    album_id: str = Field(index=True)
    title: str
    folder_id: str = Field(index=True)
    folder_name: str
    page: int = 1
    cached_at: datetime = Field(default_factory=utc_now)


class JmSessionCookie(SQLModel, table=True):
    """当前 JM 登录用户名状态表。"""

    __tablename__ = "jm_session_cookie"

    key: str = Field(primary_key=True)
    value: str
    updated_at: datetime = Field(default_factory=utc_now)


class JmAccountCookie(SQLModel, table=True):
    """按 JM 账号隔离的登录 Cookie 表。"""

    __tablename__ = "jm_account_cookie"

    username: str = Field(primary_key=True)
    key: str = Field(primary_key=True)
    value: str
    updated_at: datetime = Field(default_factory=utc_now)


class JmAccountPassword(SQLModel, table=True):
    """按 JM 账号隔离的登录密码表（本地自用，仅用于 401 后自动重登）。"""

    __tablename__ = "jm_account_password"

    username: str = Field(primary_key=True)
    password: str
    updated_at: datetime = Field(default_factory=utc_now)
