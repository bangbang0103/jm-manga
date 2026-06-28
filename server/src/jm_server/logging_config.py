"""Logging setup for jm-manga-server."""

from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

from .config import ServerConfig


def _jmcomic_log_bridge(topic: str, msg: object, e: BaseException | None = None) -> None:
    """Bridge jmcomic's custom log calls into Python logging."""
    logger = logging.getLogger("jmcomic")
    message = f"[{topic}] {msg}"
    if e is not None:
        logger.exception(message, exc_info=e)
    else:
        logger.info(message)


def setup_logging(config: ServerConfig) -> None:
    """Configure Python logging and wire jmcomic logs."""
    level = getattr(logging, config.log_level.upper(), logging.INFO)

    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stdout)]

    if config.log_file:
        log_path = Path(config.log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        handlers.append(
            RotatingFileHandler(
                log_path,
                maxBytes=config.log_max_bytes,
                backupCount=config.log_backup_count,
                encoding="utf-8",
            )
        )

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
    )
    for handler in handlers:
        handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    # Avoid duplicate handlers if setup_logging is called multiple times.
    root_logger.handlers = handlers

    # Wire jmcomic logging.
    try:
        import jmcomic

        jmcomic.JmModuleConfig.FLAG_ENABLE_JM_LOG = config.jm_log_enabled
        jmcomic.JmModuleConfig.EXECUTOR_LOG = _jmcomic_log_bridge
    except Exception:
        logging.getLogger(__name__).warning("Failed to configure jmcomic logging", exc_info=True)
