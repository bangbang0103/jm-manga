import logging

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel
from sqlmodel.ext.asyncio.session import AsyncSession

from jm_manga_server.auth import verify_auth
from jm_manga_server.cookies import (
    delete_jm_password,
    load_current_jm_user,
    save_current_jm_user,
    save_jm_cookies,
    save_jm_password,
)
from jm_manga_server.dependencies import (
    get_current_jm_user,
    get_db_session,
    get_jm_client,
)

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)


class JmLoginPayload(BaseModel):
    username: str
    password: str


async def _apply_login(client, username: str, resp) -> None:
    """将登录返回的 cookies 应用到客户端并持久化到该账号下。"""
    cookies = dict(resp.resp.cookies)
    cookies.update({"AVS": resp.res_data.get("s", "")})
    client.option.update_cookies(cookies)
    if client._session is not None:
        client._session.cookies.update(cookies)
    await save_jm_cookies(username, cookies)


@router.post("/jm")
async def jm_login(
    request: Request,
    payload: JmLoginPayload,
    _auth: bool = Depends(verify_auth),
    client=Depends(get_jm_client),
    session: AsyncSession = Depends(get_db_session),
):
    """使用 JMComic 账号密码登录并持久化 cookies，不自动同步收藏夹。"""
    lock = request.app.state.jm_lock
    async with lock:
        try:
            resp = await client.login(payload.username, payload.password)
        except Exception as e:
            logger.warning("JM login failed for user %s: %s", payload.username, e)
            raise HTTPException(status_code=401, detail="JM login failed") from e

        await _apply_login(client, payload.username, resp)
        await save_current_jm_user(payload.username)
        encryption_key = request.app.state.settings.jm_password_encryption_key
        await save_jm_password(payload.username, payload.password, encryption_key)

    return {
        "status": "ok",
        "username": payload.username,
    }


@router.post("/test")
async def jm_test_login(
    request: Request,
    payload: JmLoginPayload,
    _auth: bool = Depends(verify_auth),
    client=Depends(get_jm_client),
):
    """测试 JMComic 账号密码是否可以登录，不保存 cookies。"""
    lock = request.app.state.jm_lock
    async with lock:
        try:
            await client.login(payload.username, payload.password)
        except Exception as e:
            logger.warning("JM test login failed for user %s: %s", payload.username, e)
            raise HTTPException(status_code=401, detail="JM login failed") from e
    return {"status": "ok", "username": payload.username}


@router.get("/me")
async def current_user(user: str = Depends(get_current_jm_user)):
    """获取当前登录的 JM 用户名。"""
    if not user:
        raise HTTPException(status_code=401, detail="Not logged in")
    return {"username": user}


@router.post("/logout")
async def jm_logout(
    request: Request,
    x_jm_username: str | None = Header(None, alias="X-JM-Username"),
    client=Depends(get_jm_client),
):
    """登出 JM 账号。

    如果请求头携带 X-JM-Username，则清除该账号的 cookies；
    否则清除当前用户及其 cookies。
    """
    from jm_manga_server.cookies import save_jm_cookies

    lock = request.app.state.jm_lock
    async with lock:
        user = x_jm_username or await load_current_jm_user()
        if user:
            await save_jm_cookies(user, {})
            await delete_jm_password(user)
            current = await load_current_jm_user()
            if current == user:
                await save_current_jm_user(None)

        # 如果没有任何账号信息，清空当前客户端 cookies
        if client._session is not None:
            client._session.cookies.clear()
        client.option.headers = {}
    return {"status": "ok"}
