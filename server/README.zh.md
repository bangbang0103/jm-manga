# JM Manga Server

为 JM Manga Flutter 客户端提供的自托管加速服务。它通过本地 FastAPI 服务代理 JM 移动端 API 与图片 CDN，底层使用 [jmcomic](https://github.com/hect0x7/ComicRider) Python 库。

Flutter 客户端**不需要任何代码改动**，只需把现有的「自定义 API 域名」和「自定义图片域名」指向本服务即可。

## 特性

- 透明代理 JM 移动端 API，返回数据按 Flutter 客户端的 timestamp 重新加密。
- 图片 CDN 透明代理，带积极的磁盘 LRU 缓存。
- API 响应内存 LRU 缓存（`/login`、`/favorite` 等有状态接口除外）。
- Cookie 透传，Flutter 应用保持登录状态；每次请求使用独立的 jmcomic client，避免请求间串号。
- 支持 YAML 配置文件或环境变量。

## 快速开始

### 使用 uv（裸 Python）

```bash
cd server
uv sync
uv run uvicorn jm_server.main:app --host 0.0.0.0 --port 8080
```

或使用辅助脚本：

```bash
chmod +x run.sh
./run.sh
```

### 使用 Docker

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

### 使用 Docker Compose

```bash
cd server
docker compose up -d
```

## 配置

复制或编辑 `config.yml`。所有字段都是可选的，默认值如下：

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

# 公共基础 URL，用于改写图片主机引用（例如反代场景）。
# 未设置时会依次尝试 X-Forwarded-* / Forwarded header，最后回退到请求自身的 scheme 与 Host。
# public_base_url: https://your-server.com
```

环境变量会覆盖配置文件：

| 变量 | 对应配置 |
|---|---|
| `JM_SERVER_HOST` | `host` |
| `JM_SERVER_PORT` | `port` |
| `JM_SERVER_LOG_LEVEL` | `log_level` |
| `JM_SERVER_LOG_FILE` | `log_file` |
| `JM_SERVER_API_CACHE_TTL` | `api_cache_ttl` |
| `JM_SERVER_IMAGE_CACHE_MAX_GB` | `image_cache_max_gb` |
| `JM_SERVER_JM_LOG_ENABLED` | `jm_log_enabled` |
| `JM_SERVER_PUBLIC_BASE_URL` | `public_base_url` |

## 接入 Flutter 客户端

1. 打开 App，进入**设置 → 高级 → 自定义域名**。
2. 把服务端地址（例如 `https://your-server.com`）同时添加到：
   - 自定义 API 域名
   - 自定义图片域名
3. 将服务端条目移动到两个列表的顶部。
4. 返回 App，请求就会通过服务端转发。

## 开发

```bash
uv sync --extra dev
uv run pytest
```

## 说明

- 服务端使用 Flutter 客户端 `tokenparam` 头中的 timestamp 重新加密 API 响应，因此 Flutter 端可以正常解密。
- `/chapter_view_template` 端点原样透传 HTML，因为 Flutter 客户端需要从中提取 `scramble_id`；返回的 HTML 中的 `imghost` 会被改写为指向本服务。反代部署时，请设置 `public_base_url` 或暴露 `X-Forwarded-Proto` / `Forwarded` 头，使改写后的 URL 与公共入口一致。
- 服务端未实现身份认证；请在可信网络中运行，或放在带有你自己访问控制的反代之后。
