import asyncio
import hashlib
import hmac
import os
import pathlib
import time

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import FileResponse

from jm_manga_server.dependencies import get_jm_client

router = APIRouter(prefix="/images", tags=["images"])


def _sign(message: str, secret: str) -> str:
    return hmac.new(secret.encode(), message.encode(), hashlib.sha256).hexdigest()


def generate_image_token(photo_id: str, image_index: int, ttl: int, secret: str) -> str:
    """生成图片访问签名 token。"""
    exp = int(time.time()) + ttl
    payload = f"{photo_id}:{image_index}:{exp}"
    signature = _sign(payload, secret)
    return f"{payload}:{signature}"


def verify_image_token(token: str, photo_id: str, image_index: int, secret: str) -> bool:
    """校验图片访问签名 token。"""
    try:
        parts = token.split(":")
        if len(parts) != 4:
            return False
        t_photo_id, t_image_index, exp, signature = parts
        if t_photo_id != photo_id or int(t_image_index) != image_index:
            return False
        if int(exp) < time.time():
            return False
        payload = f"{photo_id}:{image_index}:{exp}"
        expected = _sign(payload, secret)
        return hmac.compare_digest(signature, expected)
    except Exception:
        return False


@router.get("/{photo_id}/{image_index}")
async def image_proxy(
    request: Request,
    photo_id: str,
    image_index: int,
    token: str = Query(...),
    client=Depends(get_jm_client),
):
    """图片代理：校验签名后返回解码后的图片。"""
    settings = request.app.state.settings
    secret = settings.image_sign_secret or settings.api_token or ""
    if not verify_image_token(token, photo_id, image_index, secret):
        raise HTTPException(status_code=403, detail="Invalid or expired image token")

    cache_dir = pathlib.Path(settings.cache_dir) / "images" / photo_id
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache_path = cache_dir / f"{image_index}.jpg"
    tmp_path = cache_path.with_suffix(".tmp.jpg")

    if cache_path.exists():
        return FileResponse(cache_path, media_type="image/jpeg")

    cache_key = f"{photo_id}:{image_index}"
    write_locks = request.app.state.image_write_locks
    if cache_key not in write_locks:
        write_locks[cache_key] = asyncio.Lock()
    write_lock = write_locks[cache_key]

    async with request.app.state.image_semaphore:
        async with write_lock:
            # 二次检查，避免并发请求重复下载
            if cache_path.exists():
                return FileResponse(cache_path, media_type="image/jpeg")

            # 下载并解码图片
            photo = await client.get_photo_detail(photo_id)
            if image_index < 0 or image_index >= len(photo.page_arr):
                raise HTTPException(status_code=400, detail="Image index out of range")
            image_url = photo.get_img_data_original(photo.page_arr[image_index])
            image = await client.get_jm_image(image_url)

            # 使用 jmcomic 的解码逻辑保存图片（同步 IO 卸载到线程池）
            scramble_id = photo.scramble_id if photo.scramble_id else None
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, image.transfer_to, tmp_path, scramble_id)
            os.replace(tmp_path, cache_path)

    return FileResponse(cache_path, media_type="image/jpeg")
