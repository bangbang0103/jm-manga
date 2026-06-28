# JM Manga Server

Self-hosted acceleration server for the JM Manga Flutter app. It proxies JM's
mobile API and image CDN through a local FastAPI service backed by the
[jmcomic](https://github.com/hect0x7/ComicRider) Python library.

The Flutter client does **not** need any code changes. You only point its
existing "Custom API Domain" and "Custom Image Domain" settings at this server.

## Features

- Transparent API proxying with responses re-encrypted for the Flutter client.
- Image CDN proxying with an aggressive on-disk LRU cache.
- In-memory LRU cache for API responses (login/favorite excluded).
- Cookie passthrough so the Flutter app stays logged in, with per-request jmcomic client isolation to prevent cross-request cookie leaks.
- Configurable via YAML or environment variables.

## Quick start

### With uv (bare Python)

```bash
cd server
uv sync
uv run uvicorn jm_server.main:app --host 0.0.0.0 --port 8080
```

Or use the helper script:

```bash
chmod +x run.sh
./run.sh
```

### With Docker

```bash
cd server
docker build -t jm-manga-server .
docker run -d \
  -p 8080:8080 \
  -v ./cache:/app/cache \
  -v ./logs:/app/logs \
  -e JM_SERVER_IMAGE_CACHE_DIR=/app/cache/images \
  -e JM_SERVER_LOG_FILE=/app/logs/server.log \
  jm-manga-server
```

### With Docker Compose

```bash
cd server
docker compose up -d
```

## Configuration

Copy or edit `config.yml`. All fields are optional; defaults are shown below.

```yaml
host: 0.0.0.0
port: 8080
log_level: INFO
log_file: logs/server.log
log_max_bytes: 10485760
log_backup_count: 5
api_cache_ttl: 60
api_cache_size: 1000
image_cache_dir: ./cache/images
image_cache_max_gb: 50
jm_log_enabled: false

# Public base URL used to rewrite image host references (e.g. behind a reverse proxy).
# When unset the server falls back to X-Forwarded-* / Forwarded headers, then the request URL.
# public_base_url: https://your-server.com
```

Environment variables override the config file:

| Variable | Maps to |
|---|---|
| `JM_SERVER_HOST` | `host` |
| `JM_SERVER_PORT` | `port` |
| `JM_SERVER_LOG_LEVEL` | `log_level` |
| `JM_SERVER_LOG_FILE` | `log_file` |
| `JM_SERVER_API_CACHE_TTL` | `api_cache_ttl` |
| `JM_SERVER_IMAGE_CACHE_MAX_GB` | `image_cache_max_gb` |
| `JM_SERVER_JM_LOG_ENABLED` | `jm_log_enabled` |
| `JM_SERVER_PUBLIC_BASE_URL` | `public_base_url` |

## Connecting the Flutter app

1. Open the app and go to **Settings → Advanced → Custom Domain**.
2. Add your server URL (e.g. `https://your-server.com`) to both:
   - Custom API domains
   - Custom image domains
3. Move the server entry to the top of each list.
4. Return to the app; requests will now flow through the server.

## Development

```bash
uv sync --extra dev
uv run pytest
```

## Notes

- The server re-encrypts API responses using the timestamp from the Flutter
  client's `tokenparam` header, so the Flutter app can decrypt them normally.
- The `/chapter_view_template` endpoint is passed through as raw HTML because
  the Flutter client extracts `scramble_id` from that HTML. The `imghost` value
  inside the HTML is rewritten to point back at this server. Set `public_base_url`
  (or expose `X-Forwarded-Proto`/`Forwarded` headers) when running behind a reverse
  proxy so the rewritten URL matches your public endpoint.
- No authentication is implemented; run the server on a trusted network or
  behind a reverse proxy with your own access control.
