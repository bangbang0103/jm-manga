import asyncio
import logging
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Request, Response
from fastapi.responses import FileResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from jm_manga_server.auth import verify_auth
from jm_manga_server.config import Settings
from jm_manga_server.cookies import (
    load_current_jm_user,
    load_jm_cookies,
)
from jm_manga_server.database import init_db
from jm_manga_server.dependencies import get_db_session
from jm_manga_server.exceptions import (
    ApiError,
    api_error_handler,
    http_exception_handler,
)
from jm_manga_server.jm_client import create_jm_client
from jm_manga_server.mdns import MdnsAdvertiser
from jm_manga_server.network import validate_network_settings
from jm_manga_server.routers import (
    albums,
    auth,
    categories,
    covers,
    favorites,
    images,
    progress,
    search,
    server,
)
from jm_manga_server.version import VERSION

logger = logging.getLogger(__name__)


def _configure_logging(log_level: str) -> None:
    """配置 root logger 与 uvicorn 访问日志级别。"""
    level = getattr(logging, log_level.upper(), logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    # 降低第三方库的默认噪音
    logging.getLogger("uvicorn.access").setLevel(level)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期：初始化与清理。"""
    from pathlib import Path

    settings = Settings()
    _configure_logging(settings.log_level)
    app.state.settings = settings
    app.state.network_mode = validate_network_settings(settings)
    logger.info("Running in %s network mode", app.state.network_mode)

    Path(settings.db_path).parent.mkdir(parents=True, exist_ok=True)
    Path(settings.cache_dir).mkdir(parents=True, exist_ok=True)
    app.state.jm_client = create_jm_client(settings)
    app.state.jm_lock = asyncio.Lock()
    app.state.jm_semaphore = asyncio.Semaphore(settings.jm_concurrency)
    app.state.image_semaphore = asyncio.Semaphore(settings.image_concurrency)
    app.state.image_write_locks: dict[str, asyncio.Lock] = {}
    app.state.started_at = datetime.now(timezone.utc)

    await init_db(settings)

    current_user = await load_current_jm_user()

    # 恢复当前 JM 账号的登录 cookies
    if current_user:
        cookies = await load_jm_cookies(current_user)
        if cookies:
            app.state.jm_client.option.update_cookies(cookies)
            if app.state.jm_client._session is not None:
                app.state.jm_client._session.cookies.update(cookies)

    # 启动 mDNS 广播
    advertiser: MdnsAdvertiser | None = None
    if settings.mdns_enabled:
        advertiser = MdnsAdvertiser(port=settings.port)
        await advertiser.start()
    app.state.mdns_advertiser = advertiser

    yield

    if advertiser is not None:
        await advertiser.stop()
    await app.state.jm_client.close()


class _MetricsCollector:
    """内存中的最小 metrics 收集器，返回 Prometheus 文本格式。"""

    def __init__(self) -> None:
        self.requests_total: int = 0
        self.errors_total: int = 0
        self.request_durations: list[float] = []
        self.max_durations = 10_000

    def observe(self, status_code: int, duration: float) -> None:
        self.requests_total += 1
        if status_code >= 500:
            self.errors_total += 1
        self.request_durations.append(duration)
        if len(self.request_durations) > self.max_durations:
            self.request_durations = self.request_durations[-self.max_durations :]

    @property
    def _avg_duration(self) -> float:
        if not self.request_durations:
            return 0.0
        return sum(self.request_durations) / len(self.request_durations)

    def render(self) -> str:
        return (
            "# HELP jm_manga_requests_total Total HTTP requests\n"
            "# TYPE jm_manga_requests_total counter\n"
            f"jm_manga_requests_total {self.requests_total}\n"
            "# HELP jm_manga_errors_total Total HTTP 5xx responses\n"
            "# TYPE jm_manga_errors_total counter\n"
            f"jm_manga_errors_total {self.errors_total}\n"
            "# HELP jm_manga_request_duration_seconds_avg Average request duration\n"
            "# TYPE jm_manga_request_duration_seconds_avg gauge\n"
            f"jm_manga_request_duration_seconds_avg {self._avg_duration:.6f}\n"
        )


_metrics = _MetricsCollector()


app = FastAPI(title="JM Manga Server", lifespan=lifespan)
app.add_exception_handler(ApiError, api_error_handler)
app.add_exception_handler(HTTPException, http_exception_handler)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> Response:
    """未捕获异常兜底：返回统一 500，避免堆栈/敏感信息外泄。"""
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    return Response(
        status_code=500,
        content='{"code":"ERROR","message":"Internal server error"}',
        media_type="application/json",
    )


@app.middleware("http")
async def access_log_middleware(request: Request, call_next):
    """记录访问日志与基础 metrics。"""
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start
    _metrics.observe(response.status_code, duration)
    logger.info(
        "%s %s %s - %.4fs",
        request.method,
        request.url.path,
        response.status_code,
        duration,
    )
    return response


def _metrics_endpoint(request: Request) -> Response:
    settings = getattr(request.app.state, "settings", Settings())
    if not settings.enable_metrics:
        raise HTTPException(status_code=404, detail="Not found")
    return Response(content=_metrics.render(), media_type="text/plain")


app.include_router(
    search.router,
    prefix="/api/v1",
    dependencies=[Depends(verify_auth)],
)
app.include_router(
    categories.router,
    prefix="/api/v1",
    dependencies=[Depends(verify_auth)],
)
app.include_router(
    albums.router,
    prefix="/api/v1",
    dependencies=[Depends(verify_auth)],
)
app.include_router(
    images.router,
    prefix="/api/v1",
)
app.include_router(
    covers.router,
    prefix="/api/v1",
)
app.include_router(
    auth.router,
    prefix="/api/v1",
    dependencies=[Depends(verify_auth)],
)
app.include_router(
    progress.router,
    prefix="/api/v1",
    dependencies=[Depends(verify_auth)],
)
app.include_router(
    favorites.router,
    prefix="/api/v1",
    dependencies=[Depends(verify_auth)],
)
app.include_router(
    server.router,
    prefix="/api/v1",
)
app.add_api_route("/metrics", _metrics_endpoint, methods=["GET"])


@app.get("/health")
def health():
    """Liveness probe：保持固定 ok，仅用于判断进程是否存活。"""
    started_at = getattr(app.state, "started_at", datetime.now(timezone.utc))
    uptime = datetime.now(timezone.utc) - started_at
    return {
        "status": "ok",
        "version": VERSION,
        "uptime_seconds": int(uptime.total_seconds()),
    }


@app.get("/ready")
async def ready(session: AsyncSession = Depends(get_db_session)):
    """Readiness probe：确认数据库可访问。失败时返回 503。"""
    try:
        await session.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as exc:
        logger.error("Readiness check failed: %s", exc)
        raise HTTPException(status_code=503, detail="Database not ready") from exc


def _web_root(settings: Settings) -> Path:
    root = Path(settings.web_dir).expanduser()
    if not root.is_absolute():
        root = Path.cwd() / root
    return root.resolve()


def _is_reserved_server_path(path: str) -> bool:
    return path == "api" or path.startswith("api/") or path in {"health", "ready", "metrics"}


def _serve_web_asset(request: Request, full_path: str = "") -> FileResponse:
    if _is_reserved_server_path(full_path):
        raise HTTPException(status_code=404, detail="Not found")

    settings = getattr(request.app.state, "settings", Settings())
    root = _web_root(settings)
    index = root / "index.html"
    if not index.is_file():
        raise HTTPException(status_code=404, detail="Web app not built")

    target = (root / full_path).resolve()
    try:
        target.relative_to(root)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Not found") from exc

    if target.is_file():
        return FileResponse(target)
    return FileResponse(index)


@app.get("/", include_in_schema=False)
def web_root(request: Request):
    return _serve_web_asset(request)


@app.get("/{full_path:path}", include_in_schema=False)
def web_spa_fallback(request: Request, full_path: str):
    return _serve_web_asset(request, full_path)
