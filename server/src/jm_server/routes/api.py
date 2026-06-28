"""API routes that replay JM endpoints through jmcomic."""

from __future__ import annotations

import logging
import re
from typing import Any

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, JSONResponse, Response

from ..config import ServerConfig
from ..crypto import build_envelope, decode_jm_response, extract_timestamp_from_tokenparam

logger = logging.getLogger(__name__)

router = APIRouter()

# Paths that should never be cached because they depend on or mutate user state.
_NON_CACHEABLE_PATHS = {"/favorite", "/login"}


def _should_cache(path: str) -> bool:
    return path not in _NON_CACHEABLE_PATHS


def _extract_client_timestamp(request: Request) -> int:
    tokenparam = request.headers.get("tokenparam") or request.headers.get("Tokenparam")
    ts = extract_timestamp_from_tokenparam(tokenparam)
    if ts is None:
        logger.warning(
            "Missing or invalid tokenparam header (%r); falling back to current timestamp",
            tokenparam,
        )
        from time import time as _time
        return int(_time())
    logger.info("Using client timestamp %s from tokenparam %r", ts, tokenparam)
    return ts


def _to_plain(data: Any) -> Any:
    """Convert jmcomic's AdvancedDict / model objects into plain dicts/lists."""
    if hasattr(data, "to_json"):
        return data.to_json()
    if hasattr(data, "__dict__"):
        return dict(data.__dict__)
    return data


async def _handle_api(
    request: Request,
    path: str,
) -> Response:
    client = request.app.state.client
    cache = request.app.state.api_cache

    method = request.method
    query = str(request.query_params)
    cookie_header = request.headers.get("cookie") or request.headers.get("Cookie")
    body_data: dict[str, Any] | None = None

    if method == "POST":
        form = await request.form()
        body_data = dict(form)

    if _should_cache(path):
        cached_plain = cache.get(method, path, query, cookie_header or "")
        if cached_plain is not None:
            logger.debug("API cache hit: %s %s", method, path)
            timestamp = _extract_client_timestamp(request)
            cached_envelope = build_envelope(cached_plain, timestamp, path=path)
            response = JSONResponse(content=cached_envelope)
            response.headers["X-JM-Timestamp"] = str(timestamp)
            return response

    try:
        resp = await client.api_request(
            method=method,
            path=path,
            params=dict(request.query_params),
            data=body_data,
            cookie_header=cookie_header,
        )
    except Exception as exc:
        logger.exception("jmcomic request failed: %s %s", method, path)
        return JSONResponse(
            status_code=502,
            content={"code": 502, "message": f"Upstream request failed: {exc}"},
        )

    try:
        plain_data = decode_jm_response(resp, path)
    except Exception as exc:
        logger.exception("Failed to decode JM response: %s %s", method, path)
        return JSONResponse(
            status_code=502,
            content={"code": 502, "message": f"Failed to decode upstream response: {exc}"},
        )

    timestamp = _extract_client_timestamp(request)
    envelope = build_envelope(plain_data, timestamp, path=path)

    if _should_cache(path):
        cache.set(method, path, query, cookie_header or "", plain_data)

    response = JSONResponse(content=envelope)
    response.headers["X-JM-Timestamp"] = str(timestamp)
    return response


@router.get("/search")
async def search(request: Request) -> Response:
    return await _handle_api(request, "/search")


@router.get("/album")
async def album(request: Request) -> Response:
    return await _handle_api(request, "/album")


@router.get("/chapter")
async def chapter(request: Request) -> Response:
    return await _handle_api(request, "/chapter")


@router.get("/categories/filter")
async def categories_filter(request: Request) -> Response:
    return await _handle_api(request, "/categories/filter")


def _parse_forwarded(header: str) -> tuple[str | None, str | None]:
    """Extract proto and host from a Forwarded header (RFC 7239)."""
    proto_match = re.search(r'(?:^|;\s*)proto=(\w+)', header)
    host_match = re.search(r'(?:^|;\s*)host=([^;\s,]+)', header)
    return (
        proto_match.group(1) if proto_match else None,
        host_match.group(1) if host_match else None,
    )


def _server_imghost(request: Request) -> str:
    """Build the image host URL that points back at this server.

    Priority:
        1. Explicit public_base_url in server config.
        2. X-Forwarded-Proto / X-Forwarded-Host headers.
        3. Forwarded header (RFC 7239).
        4. Request scheme and Host header.
    """
    config: ServerConfig = request.app.state.config
    public_base_url = config.public_base_url
    if public_base_url:
        return public_base_url.rstrip("/")

    scheme: str | None = request.headers.get("x-forwarded-proto")
    host = request.headers.get("x-forwarded-host")

    forwarded = request.headers.get("forwarded")
    if forwarded and (scheme is None or host is None):
        forwarded_proto, forwarded_host = _parse_forwarded(forwarded)
        if scheme is None:
            scheme = forwarded_proto
        if host is None:
            host = forwarded_host

    scheme = scheme or request.scope.get("scheme", "http")
    host = host or request.headers.get("host") or "127.0.0.1:8080"
    return f"{scheme}://{host}"


def _replace_imghost(html: str, imghost: str) -> str:
    """Rewrite the image host inside chapter_view_template HTML to the server."""
    return re.sub(
        r"(imghost\s*:\s*['\"])[^'\"]+(['\"])",
        rf"\g<1>{imghost}\g<2>",
        html,
    )


@router.get("/chapter_view_template")
async def chapter_view_template(request: Request) -> Response:
    client = request.app.state.client
    cookie_header = request.headers.get("cookie") or request.headers.get("Cookie")

    try:
        html = await client.scramble_page(
            params=dict(request.query_params),
            cookie_header=cookie_header,
        )
    except Exception as exc:
        logger.exception("jmcomic scramble page request failed")
        return JSONResponse(
            status_code=502,
            content={"code": 502, "message": f"Upstream request failed: {exc}"},
        )

    html = _replace_imghost(html, _server_imghost(request))
    return HTMLResponse(content=html)


@router.post("/login")
async def login(request: Request) -> Response:
    client = request.app.state.client
    form = await request.form()
    username = form.get("username", "")
    password = form.get("password", "")

    try:
        res_data, cookies = await client.login(str(username), str(password))
    except Exception as exc:
        logger.exception("jmcomic login failed")
        return JSONResponse(
            status_code=502,
            content={"code": 502, "message": f"Login failed: {exc}"},
        )

    plain_data = _to_plain(res_data)
    timestamp = _extract_client_timestamp(request)
    envelope = build_envelope(plain_data, timestamp, path="/login")

    response = JSONResponse(content=envelope)
    for name, value in cookies.items():
        response.set_cookie(key=name, value=value)
    return response


@router.get("/favorite")
async def get_favorite(request: Request) -> Response:
    return await _handle_api(request, "/favorite")


@router.post("/favorite")
async def post_favorite(request: Request) -> Response:
    return await _handle_api(request, "/favorite")
