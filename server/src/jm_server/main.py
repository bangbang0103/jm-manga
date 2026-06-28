"""FastAPI application entry point."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

from .cache import ImageDiskCache, TimedLRUCache
from .client import JmServerClient
from .config import ServerConfig, load_config
from .logging_config import setup_logging
from .routes import api, image

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = getattr(app.state, "_injected_config", None) or load_config()
    setup_logging(config)
    logger.info("Starting jm-manga-server")

    app.state.config = config
    app.state.api_cache = TimedLRUCache(
        max_size=config.api_cache_size,
        ttl_seconds=config.api_cache_ttl,
    )
    app.state.image_cache = ImageDiskCache(
        cache_dir=config.image_cache_dir,
        max_bytes=config.image_cache_max_gb * 1024 * 1024 * 1024,
    )

    client = getattr(app.state, "_injected_client", None)
    if client is None:
        client = JmServerClient(config)
        try:
            await client.setup()
        except Exception:
            logger.exception("Failed to initialize jmcomic client; requests will fail until replaced")
    app.state.client = client

    yield

    try:
        await client.close()
    except Exception:
        logger.exception("Error closing jmcomic client")
    logger.info("jm-manga-server stopped")


def create_app() -> FastAPI:
    app = FastAPI(
        title="JM Manga Server",
        description="Self-hosted acceleration server for JM Manga.",
        version="0.1.0",
        lifespan=lifespan,
    )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        if isinstance(exc, HTTPException):
            raise exc
        logger.exception("Unhandled error: %s", exc)
        return JSONResponse(
            status_code=502,
            content={"code": 502, "message": f"Server error: {exc}"},
        )

    app.include_router(api.router)
    app.include_router(image.router)
    return app


app = create_app()
