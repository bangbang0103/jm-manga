import time

from jm_server.cache import ImageDiskCache, TimedLRUCache


def test_timed_lru_cache_basic():
    cache = TimedLRUCache(max_size=2, ttl_seconds=60)
    cache.set("GET", "/album", "id=1", "", {"id": "1"})
    assert cache.get("GET", "/album", "id=1", "") == {"id": "1"}
    assert cache.get("GET", "/album", "id=2", "") is None


def test_timed_lru_cache_expires():
    cache = TimedLRUCache(max_size=2, ttl_seconds=0)
    cache.set("GET", "/album", "id=1", "", {"id": "1"})
    time.sleep(0.01)
    assert cache.get("GET", "/album", "id=1", "") is None


def test_timed_lru_cache_eviction():
    cache = TimedLRUCache(max_size=2, ttl_seconds=60)
    cache.set("GET", "/a", "", "", 1)
    cache.set("GET", "/b", "", "", 2)
    cache.set("GET", "/c", "", "", 3)
    assert cache.get("GET", "/a", "", "") is None
    assert cache.get("GET", "/b", "", "") == 2
    assert cache.get("GET", "/c", "", "") == 3


def test_image_disk_cache(tmp_path):
    cache_dir = tmp_path / "images"
    cache = ImageDiskCache(cache_dir=cache_dir, max_bytes=1024 * 1024)

    url = "https://cdn.example.com/media/photos/123/00001.jpg?scramble_id=456"
    data = b"fake-image-bytes"
    cache.set(url, data, content_type="image/jpeg")

    cached = cache.get(url)
    assert cached == data

    # scramble_id should not affect cache key.
    url2 = "https://cdn.example.com/media/photos/123/00001.jpg?scramble_id=789"
    assert cache.get(url2) == data
