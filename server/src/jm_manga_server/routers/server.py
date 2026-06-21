import pathlib

from fastapi import APIRouter, Depends, Request

from jm_manga_server.auth import verify_auth

router = APIRouter(prefix="/server", tags=["server"])


def _dir_size(path: pathlib.Path) -> int:
    """递归计算目录下所有文件的总字节数。"""
    if not path.exists():
        return 0
    total = 0
    for item in path.rglob("*"):
        if item.is_file():
            total += item.stat().st_size
    return total


def _file_size(path: pathlib.Path) -> int:
    """计算单个文件大小；文件不存在时返回 0。"""
    if not path.is_file():
        return 0
    return path.stat().st_size


@router.get("/cache", dependencies=[Depends(verify_auth)])
async def cache_sizes(request: Request):
    """返回服务端缓存与数据库占用大小。"""
    settings = request.app.state.settings
    cache_root = pathlib.Path(settings.cache_dir)
    return {
        "covers": _dir_size(cache_root / "covers"),
        "images": _dir_size(cache_root / "images"),
        "database": _file_size(pathlib.Path(settings.db_path)),
    }
