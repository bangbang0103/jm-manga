import asyncio
import pathlib
import re

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi import Path as PathParam
from fastapi.responses import FileResponse

from jm_manga_server.auth import verify_auth
from jm_manga_server.dependencies import get_jm_client

router = APIRouter(prefix="/covers", tags=["covers"])

_SIZE_PATTERN = re.compile(r"^[a-zA-Z0-9_]*$")


def _write_cover_sync(cache_path: pathlib.Path, content: bytes) -> None:
    """同步写入封面缓存文件（供线程池调用）。"""
    tmp_path = cache_path.with_suffix(".jpg.tmp")
    with open(tmp_path, "wb") as f:
        f.write(content)
    tmp_path.replace(cache_path)


@router.get("/{album_id}", dependencies=[Depends(verify_auth)])
async def cover_proxy(
    request: Request,
    album_id: str = PathParam(...),
    size: str = "",
    client=Depends(get_jm_client),
):
    """封面代理：下载并缓存本子封面图。"""
    from jmcomic import JmcomicText

    if not _SIZE_PATTERN.match(size):
        raise HTTPException(status_code=400, detail="Invalid size parameter")

    settings = request.app.state.settings
    cache_dir = pathlib.Path(settings.cache_dir) / "covers"
    cache_dir.mkdir(parents=True, exist_ok=True)
    suffix = size if size else ""
    cache_path = (cache_dir / f"{album_id}{suffix}.jpg").resolve()

    # 路径穿越防护：解析后的路径必须仍在缓存目录内
    if not str(cache_path).startswith(str(cache_dir.resolve())):
        raise HTTPException(status_code=400, detail="Invalid cover path")

    if cache_path.exists():
        return FileResponse(cache_path, media_type="image/jpeg")

    cache_key = f"{album_id}:{size}"
    write_locks = request.app.state.image_write_locks
    if cache_key not in write_locks:
        write_locks[cache_key] = asyncio.Lock()
    write_lock = write_locks[cache_key]

    async with request.app.state.image_semaphore:
        async with write_lock:
            # 二次检查，避免并发请求重复下载
            if cache_path.exists():
                return FileResponse(cache_path, media_type="image/jpeg")

            image_url = JmcomicText.get_album_cover_url(album_id, size=size)
            image = await client.get_jm_image(image_url)

            # 同步 IO 卸载到线程池，并原子写入
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, _write_cover_sync, cache_path, image.content)

    return FileResponse(cache_path, media_type="image/jpeg")
