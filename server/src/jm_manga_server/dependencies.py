from typing import AsyncGenerator

from fastapi import Depends, Header, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from jm_manga_server.cookies import (
    list_saved_jm_users,
    load_current_jm_user,
    load_jm_cookies,
)
from jm_manga_server.database import async_session_maker


async def get_jm_client(request: Request):
    """从应用状态获取 jmcomic 异步客户端。"""
    return request.app.state.jm_client


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """获取数据库会话。"""
    async with async_session_maker() as session:
        yield session


async def get_current_jm_user(
    request: Request,
    x_jm_username: str | None = Header(None, alias="X-JM-Username"),
) -> str:
    """获取当前 JM 登录用户名。

    优先从请求头 X-JM-Username 读取，未提供则回退到服务端保存的当前用户。
    如果请求头携带了用户名，必须校验为已保存过 cookies 的账号，防止横向越权。
    """
    if x_jm_username:
        saved_users = await list_saved_jm_users()
        current = await load_current_jm_user()
        if x_jm_username not in saved_users and x_jm_username != current:
            raise HTTPException(
                status_code=401,
                detail="Invalid X-JM-Username: account not available on this server",
            )
        return x_jm_username
    return await load_current_jm_user() or ""


async def get_explicit_jm_user(
    x_jm_username: str | None = Header(None, alias="X-JM-Username"),
) -> str:
    """获取请求显式指定的 JM 用户；未指定时不回退服务端当前用户。"""
    if not x_jm_username:
        return ""
    saved_users = await list_saved_jm_users()
    current = await load_current_jm_user()
    if x_jm_username not in saved_users and x_jm_username != current:
        raise HTTPException(
            status_code=401,
            detail="Invalid X-JM-Username: account not available on this server",
        )
    return x_jm_username


async def get_device_id(
    x_device_id: str | None = Header(None, alias="X-Device-Id"),
) -> str:
    """获取客户端设备标识。仅作为阅读记录命名空间，不作为安全身份。"""
    if not x_device_id:
        return ""
    return x_device_id.strip()[:128]


async def prepare_jm_account(
    request: Request,
    user: str = Depends(get_current_jm_user),
) -> AsyncGenerator[str, None]:
    """根据当前用户名加载对应 cookies 并设置到 jm_client。

    使用全局锁串行化所有 JM 调用，避免并发请求互相覆盖共享 client 的 cookies。
    路由函数执行完毕后清理 client cookies。

    Yields 准备后的用户名，供后续路由使用。
    """
    client = request.app.state.jm_client
    lock = request.app.state.jm_lock

    async with lock:
        try:
            if user:
                cookies = await load_jm_cookies(user)
                client.option.update_cookies(cookies)
                if client._session is not None:
                    client._session.cookies.update(cookies)
            yield user
        finally:
            client.option.headers = {}
            if client._session is not None:
                client._session.cookies.clear()
