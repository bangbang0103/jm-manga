"""Caching utilities for API responses and images."""

from __future__ import annotations

import hashlib
import json
import logging
import time
from collections import OrderedDict
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

logger = logging.getLogger(__name__)


class TimedLRUCache:
    """In-memory LRU cache with per-item TTL."""

    def __init__(self, max_size: int, ttl_seconds: int):
        self._max_size = max_size
        self._ttl = ttl_seconds
        self._cache: OrderedDict[str, tuple[Any, float]] = OrderedDict()

    def _make_key(self, *parts: str) -> str:
        return hashlib.sha256("|".join(parts).encode()).hexdigest()

    def get(self, method: str, path: str, query: str, cookie: str) -> Any | None:
        key = self._make_key(method, path, query, cookie)
        if key not in self._cache:
            return None
        value, expires_at = self._cache[key]
        if time.time() > expires_at:
            del self._cache[key]
            return None
        self._cache.move_to_end(key)
        return value

    def set(self, method: str, path: str, query: str, cookie: str, value: Any) -> None:
        key = self._make_key(method, path, query, cookie)
        self._cache[key] = (value, time.time() + self._ttl)
        self._cache.move_to_end(key)
        if len(self._cache) > self._max_size:
            self._cache.popitem(last=False)

    def clear(self) -> None:
        self._cache.clear()


class ImageDiskCache:
    """LRU disk cache for image bytes keyed by URL."""

    def __init__(self, cache_dir: Path, max_bytes: int):
        self._dir = cache_dir
        self._max_bytes = max_bytes
        self._dir.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _normalize_url(url: str) -> str:
        """Drop scheme, host, and scramble_id query param for caching."""
        parsed = urlparse(url)
        query_params = parse_qs(parsed.query, keep_blank_values=True)
        query_params.pop("scramble_id", None)
        query = urlencode(query_params, doseq=True)
        return f"{parsed.path}?{query}" if query else parsed.path

    def _cache_path(self, url: str) -> Path:
        normalized = self._normalize_url(url)
        digest = hashlib.sha256(normalized.encode()).hexdigest()
        # Shard into two-level directories to avoid too many files in one dir.
        return self._dir / digest[:2] / digest[2:4] / digest

    def _metadata_path(self, path: Path) -> Path:
        return Path(str(path) + ".meta")

    def get(self, url: str) -> bytes | None:
        path = self._cache_path(url)
        if not path.exists():
            return None
        try:
            data = path.read_bytes()
            # Update access time for LRU eviction.
            path.touch()
            return data
        except OSError:
            logger.warning("Failed to read cached image for %s", url, exc_info=True)
            return None

    def set(self, url: str, data: bytes, content_type: str | None = None) -> None:
        path = self._cache_path(url)
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            path.write_bytes(data)
            self._metadata_path(path).write_text(
                json.dumps({"content_type": content_type, "size": len(data)}),
                encoding="utf-8",
            )
            self._evict_if_needed()
        except OSError:
            logger.warning("Failed to cache image for %s", url, exc_info=True)

    def _evict_if_needed(self) -> None:
        files = [
            (f, f.stat().st_atime, f.stat().st_size)
            for f in self._dir.rglob("*")
            if f.is_file() and not f.name.endswith(".meta")
        ]
        total = sum(size for _, _, size in files)
        if total <= self._max_bytes:
            return

        files.sort(key=lambda x: x[1])
        for path, _, size in files:
            if total <= self._max_bytes:
                break
            try:
                meta = self._metadata_path(path)
                if meta.exists():
                    meta.unlink()
                path.unlink()
                total -= size
            except OSError:
                logger.warning("Failed to evict cached image %s", path, exc_info=True)
