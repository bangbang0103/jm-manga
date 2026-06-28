"""Image CDN routes with transparent proxying and disk caching."""

from __future__ import annotations

import logging
import random
from urllib.parse import urlencode

from fastapi import APIRouter, Request
from fastapi.responses import Response
from jmcomic import JmModuleConfig

logger = logging.getLogger(__name__)

router = APIRouter()


def _image_domain() -> str:
    """Pick an image CDN domain from jmcomic's configured list."""
    domains = list(JmModuleConfig.DOMAIN_IMAGE_LIST)
    return random.choice(domains) if domains else "cdn-msp.jmapiproxy1.cc"


def _build_image_url(path: str, query: str) -> str:
    domain = _image_domain()
    scheme = "https"
    url = f"{scheme}://{domain}{path}"
    if query:
        url += f"?{query}"
    return url


def _guess_content_type(data: bytes) -> str:
    """Infer image content type from file magic bytes."""
    if data.startswith(b"\x89PNG\x0d\x0a\x1a\x0a"):
        return "image/png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"GIF87a") or data.startswith(b"GIF89a"):
        return "image/gif"
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        return "image/webp"
    return "image/jpeg"


async def _serve_image(request: Request, path: str) -> Response:
    cache = request.app.state.image_cache
    client = request.app.state.client
    cookie_header = request.headers.get("cookie") or request.headers.get("Cookie")
    query = str(request.query_params)

    cache_url = _build_image_url(path, query)

    cached = cache.get(cache_url)
    if cached is not None:
        logger.debug("Image cache hit: %s", path)
        content_type = _guess_content_type(cached)
        return Response(content=cached, media_type=content_type)

    try:
        data, content_type = await client.fetch_image(cache_url, cookie_header)
    except Exception as exc:
        logger.exception("Image fetch failed: %s", cache_url)
        return Response(
            status_code=502,
            content=f"Upstream image request failed: {exc}".encode("utf-8"),
        )

    if not content_type:
        content_type = _guess_content_type(data)

    cache.set(cache_url, data, content_type=content_type)
    return Response(content=data, media_type=content_type)


@router.get("/media/albums/{album_id}{size}.jpg")
async def album_cover(
    request: Request,
    album_id: str,
    size: str = "",
) -> Response:
    path = f"/media/albums/{album_id}{size}.jpg"
    return await _serve_image(request, path)


@router.get("/media/photos/{photo_id}/{image_name}")
async def photo_image(
    request: Request,
    photo_id: str,
    image_name: str,
) -> Response:
    path = f"/media/photos/{photo_id}/{image_name}"
    return await _serve_image(request, path)
