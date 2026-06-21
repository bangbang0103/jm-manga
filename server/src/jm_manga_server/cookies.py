from datetime import datetime, timezone
from typing import Dict

from sqlmodel import select

from jm_manga_server.crypto import decrypt_password, encrypt_password
from jm_manga_server.database import async_session_maker
from jm_manga_server.models import (
    JmAccountCookie,
    JmAccountPassword,
    JmSessionCookie,
)


async def load_jm_cookies(username: str) -> Dict[str, str]:
    """从数据库加载指定 JM 账号的登录 cookies。"""
    async with async_session_maker() as session:
        result = await session.exec(
            select(JmAccountCookie).where(JmAccountCookie.username == username)
        )
        return {cookie.key: cookie.value for cookie in result.all()}


async def list_saved_jm_users() -> set[str]:
    """返回数据库中已保存 cookies 的所有 JM 用户名。"""
    async with async_session_maker() as session:
        result = await session.exec(select(JmAccountCookie.username).distinct())
        return set(result.all())


async def save_jm_cookies(username: str, cookies: Dict[str, str]) -> None:
    """保存指定 JM 账号的登录 cookies 到数据库。"""
    async with async_session_maker() as session:
        # 先删除该账号所有旧 cookies
        for cookie in await session.exec(
            select(JmAccountCookie).where(JmAccountCookie.username == username)
        ):
            await session.delete(cookie)

        for key, value in cookies.items():
            session.add(
                JmAccountCookie(
                    username=username,
                    key=key,
                    value=value,
                    updated_at=datetime.now(timezone.utc),
                )
            )
        await session.commit()


async def load_current_jm_user() -> str | None:
    """读取当前 JM 登录用户名。"""
    async with async_session_maker() as session:
        cookie = await session.get(JmSessionCookie, "_current_username")
        return cookie.value if cookie else None


async def save_current_jm_user(username: str | None) -> None:
    """保存当前 JM 登录用户名。"""
    async with async_session_maker() as session:
        if username is None:
            cookie = await session.get(JmSessionCookie, "_current_username")
            if cookie:
                await session.delete(cookie)
        else:
            existing = await session.get(JmSessionCookie, "_current_username")
            if existing:
                existing.value = username
                existing.updated_at = datetime.now(timezone.utc)
            else:
                session.add(
                    JmSessionCookie(
                        key="_current_username",
                        value=username,
                        updated_at=datetime.now(timezone.utc),
                    )
                )
        await session.commit()


async def save_jm_password(username: str, password: str, encryption_key: str | None = None) -> None:
    """保存 JM 账号密码，用于 401 后自动重登。

    若提供 encryption_key，则使用 Fernet 加密后落盘。
    """
    stored = encrypt_password(password, encryption_key) if encryption_key else password
    async with async_session_maker() as session:
        existing = await session.get(JmAccountPassword, username)
        if existing:
            existing.password = stored
            existing.updated_at = datetime.now(timezone.utc)
        else:
            session.add(
                JmAccountPassword(
                    username=username,
                    password=stored,
                    updated_at=datetime.now(timezone.utc),
                )
            )
        await session.commit()


async def load_jm_password(username: str, encryption_key: str | None = None) -> str | None:
    """读取 JM 账号密码。

    若提供 encryption_key 且密码是加密格式，则解密后返回。
    """
    async with async_session_maker() as session:
        row = await session.get(JmAccountPassword, username)
        if not row:
            return None
        if encryption_key:
            return decrypt_password(row.password, encryption_key)
        return row.password


async def delete_jm_password(username: str) -> None:
    """删除 JM 账号密码。"""
    async with async_session_maker() as session:
        row = await session.get(JmAccountPassword, username)
        if row:
            await session.delete(row)
            await session.commit()


async def try_jm_relogin(client, username: str, encryption_key: str | None = None) -> bool:
    """尝试用本地保存的密码重新登录并刷新 cookies。"""
    password = await load_jm_password(username, encryption_key)
    if not password:
        return False

    try:
        resp = await client.login(username, password)
    except Exception:
        return False

    cookies = dict(resp.resp.cookies)
    cookies.update({"AVS": resp.res_data.get("s", "")})
    client.option.update_cookies(cookies)
    if client._session is not None:
        client._session.cookies.update(cookies)
    await save_jm_cookies(username, cookies)
    return True
