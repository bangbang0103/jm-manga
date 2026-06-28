"""jmcomic async client wrapper for the server.

This module deliberately isolates per-request state:

* API / login / scramble requests create a fresh jmcomic async client for every
  HTTP request so that user cookies never leak across requests.
* Image downloads use a shared aiohttp session to keep connection reuse for
  CDN traffic, since images do not need per-user session cookies.
"""

from __future__ import annotations

import copy
import logging
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

import aiohttp
import jmcomic
from jmcomic import JmModuleConfig, JmOption

from .config import ServerConfig
from .crypto import decode_jm_response

logger = logging.getLogger(__name__)

# Do not let jmcomic populate session cookies from a global /setting call.
# The server forwards the App's Cookie header explicitly per request.
JmModuleConfig.FLAG_API_CLIENT_REQUIRE_COOKIES = False


def _parse_cookie_header(cookie_header: str | None) -> dict[str, str]:
    """Parse a Cookie header into a dict."""
    cookies: dict[str, str] = {}
    if not cookie_header:
        return cookies
    for part in cookie_header.split(";"):
        part = part.strip()
        if not part:
            continue
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        cookies[key.strip()] = value.strip()
    return cookies


class JmServerClient:
    """Wrapper around jmcomic with per-request client isolation.

    A single jmcomic async client keeps its cookies in the aiohttp session
    cookie jar. Reusing one client across requests would let request A's
    cookies leak into request B. We therefore create a fresh client for every
    API/login/scramble call and only share the connection pool for image
    downloads, which do not carry user session state.
    """

    def __init__(self, config: ServerConfig):
        self._config = config
        self._option = self._create_option()
        self._image_session: aiohttp.ClientSession | None = None

    def _create_option(self) -> JmOption:
        if self._config.jm_option_file and self._config.jm_option_file.exists():
            logger.info("Loading jmcomic option from %s", self._config.jm_option_file)
            return jmcomic.create_option_by_file(str(self._config.jm_option_file))
        logger.info("Using default jmcomic option")
        return JmOption.default()

    async def setup(self) -> None:
        """Initialize shared resources that are safe to reuse.

        This warms up the jmcomic class-level domain/cookie cache once and
        creates the shared aiohttp session used for image downloads.
        """
        if self._image_session is None:
            self._image_session = aiohttp.ClientSession()
            logger.info("Shared image download session initialized")

    async def close(self) -> None:
        if self._image_session is not None:
            await self._image_session.close()
            self._image_session = None
            logger.info("Shared image download session closed")

    def _new_api_client(
        self,
        cookie_header: str | None,
    ) -> Any:
        """Create an isolated jmcomic client seeded with the request's cookies."""
        option = copy.deepcopy(self._option)
        cookies = _parse_cookie_header(cookie_header)
        if cookies:
            option.update_cookies(cookies)
        return option.new_jm_async_client()

    async def login(
        self,
        username: str,
        password: str,
    ) -> tuple[dict[str, Any], dict[str, str]]:
        """Login via jmcomic and return (response data, cookies to forward).

        A dedicated client is used so that login response cookies do not
        contaminate the shared option template or other requests.
        """
        client = self._new_api_client(None)
        try:
            resp = await client.login(username, password)
            cookies: dict[str, str] = {}
            raw_resp = getattr(resp, "resp", None)
            if raw_resp is not None:
                cookies.update(dict(raw_resp.cookies))
            res_data = decode_jm_response(resp, path="/login")
            if isinstance(res_data, dict) and "s" in res_data:
                cookies["AVS"] = res_data["s"]
            return res_data, cookies
        finally:
            await client.close()

    async def api_request(
        self,
        method: str,
        path: str,
        params: dict[str, Any],
        data: dict[str, Any] | None,
        cookie_header: str | None,
    ) -> Any:
        """Request a JM API endpoint through an isolated jmcomic client."""
        client = self._new_api_client(cookie_header)
        try:
            is_get = method.upper() == "GET"
            kwargs: dict[str, Any] = {"require_success": False}
            if params:
                kwargs["params"] = params
            if data and not is_get:
                kwargs["data"] = data

            return await client.req_api(path, get=is_get, **kwargs)
        finally:
            await client.close()

    async def scramble_page(
        self,
        params: dict[str, Any],
        cookie_header: str | None,
    ) -> str:
        """Fetch /chapter_view_template raw HTML using an isolated client."""
        client = self._new_api_client(cookie_header)
        try:
            resp = await client.req_api(
                client.API_SCRAMBLE,
                get=True,
                params=params,
                require_success=False,
            )
            return resp.text
        finally:
            await client.close()

    async def fetch_image(
        self,
        image_url: str,
        cookie_header: str | None,
    ) -> tuple[bytes, str | None]:
        """Fetch image bytes from JM CDN using the shared image session."""
        if self._image_session is None:
            self._image_session = aiohttp.ClientSession()

        headers: dict[str, str] = {}
        if cookie_header:
            headers["Cookie"] = cookie_header

        last_error: Exception | None = None
        for attempt in range(1, 4):
            try:
                async with self._image_session.get(
                    image_url,
                    headers=headers,
                ) as resp:
                    resp.raise_for_status()
                    content_type = resp.headers.get("Content-Type")
                    return await resp.read(), content_type
            except Exception as exc:
                last_error = exc
                logger.warning(
                    "JM image fetch attempt %s/%s failed for %s: %s",
                    attempt,
                    3,
                    image_url,
                    exc,
                )

        raise RuntimeError(
            f"Failed to fetch JM image after 3 attempts: {image_url}"
        ) from last_error


@asynccontextmanager
async def managed_client(config: ServerConfig):
    """Async context manager for the jmcomic client."""
    client = JmServerClient(config)
    try:
        await client.setup()
        yield client
    finally:
        await client.close()
