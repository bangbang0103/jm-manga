# JM Manga

![JM Manga icon](docs/assets/icon.png)

个人使用的 JM 漫画阅读应用。项目采用自托管 FastAPI 后端 + Flutter 客户端架构：

- 后端负责 JM 数据访问、图片解码与缓存、阅读进度、收藏夹缓存、账号 cookies 和 Web 静态页面服务。
- Flutter 客户端负责浏览、搜索、阅读器、收藏/进度同步、服务配置和账号管理。
- Flutter Web 可以构建为 PWA，并由同一个 FastAPI 后端直接服务。

## Prepare Requirement

基础环境：

- Python 3.12+
- [uv](https://docs.astral.sh/uv/)：后端依赖和命令运行
- Flutter SDK：构建移动端和 Web 端
- Android SDK：构建 APK
- macOS + Xcode：构建 iOS app

部署环境建议：

- 局域网部署：一台常开机器，例如 Mac mini、NAS、家用 Linux 主机或内网服务器。
- 公网部署：VPS + 域名 + HTTPS 反向代理。
- 默认数据目录为 `$HOME/.jm-manga`，可通过 `DB_PATH` 和 `CACHE_DIR` 覆盖。

## Directory Structure

```text
server/
  src/jm_manga_server/       FastAPI 服务端源码
  tests/                     后端测试
  .env.example               服务端环境变量模板
  pyproject.toml             Python 项目配置

ui/
  lib/                       Flutter 客户端源码
  test/                      Flutter 测试
  assets/                    App 图标、字体等资源
  pubspec.yaml               Flutter 依赖配置

scripts/
  build.sh                   统一构建入口
  build-flutter.sh           Flutter APK / iOS / Web 构建
  build-server-package.sh    后端 Python 源码包构建
  sync-version.sh            将根 VERSION 同步到后端和 Flutter
  update-jmcomic.sh          尝试升级 JMComic 依赖并同步 lockfile

docs/
  architecture.md            架构说明
  deployment.md              部署细节
  building-mobile.md         移动端构建说明
  research/                  接口探测资料
```

生成产物目录：

```text
build/                       构建输出，不提交
server/web/                  Flutter Web 产物副本，不提交
$HOME/.jm-manga/             默认数据库和缓存目录，不提交
```

## Quick Start

后端本地运行：

```bash
cd server
cp .env.example .env
uv sync
uv run fastapi dev src/jm_manga_server/main.py
```

Flutter 客户端运行：

```bash
cd ui
flutter pub get
flutter run
```

首次打开 JM Manga 时添加服务地址和 API Token。后端鉴权使用标准 Bearer Token：

```http
Authorization: Bearer <API_TOKEN>
```

如果后端没有配置 `API_TOKEN`，鉴权会跳过。公网部署不要这样做。

## LAN Deployment Recommendation

局域网部署适合个人设备访问，推荐配置：

```bash
NETWORK_MODE=lan
HOST=0.0.0.0
PORT=8000
MDNS_ENABLED=true
DB_PATH=$HOME/.jm-manga/app.db
CACHE_DIR=$HOME/.jm-manga/cache
```

建议：

- 局域网可以先用 HTTP 访问，例如 `http://192.168.1.10:8000`。
- 如果要安装 PWA，最好给局域网也配 HTTPS；可以使用域名 + DNS-01 证书，或 `mkcert` / 私有 CA。
- Flutter 客户端可以通过服务列表页手动添加 `host:port`，也可以使用 mDNS 扫描发现服务。
- 若服务只在可信局域网使用，`API_TOKEN` 可以为空；若有访客网络、旁路由、内网穿透，仍建议设置强 token。
- 数据目录不要放在代码 release 目录里，避免更新服务时丢数据库和缓存。

## Public Deployment Recommendation

公网部署必须按生产服务处理：

```bash
NETWORK_MODE=public
ENV=production
HOST=127.0.0.1
PORT=8000
API_TOKEN=<strong-random-token>
IMAGE_SIGN_SECRET=<strong-random-secret>
JM_PASSWORD_ENCRYPTION_KEY=<strong-random-key>
DB_PATH=$HOME/.jm-manga/app.db
CACHE_DIR=$HOME/.jm-manga/cache
MDNS_ENABLED=false
```

建议：

- 后端只监听 `127.0.0.1:8000`，公网入口由 Caddy / Nginx 反向代理到 443。
- 必须启用 HTTPS。PWA 安装、Service Worker 和浏览器安全策略都依赖安全上下文。
- `API_TOKEN`、`IMAGE_SIGN_SECRET`、`JM_PASSWORD_ENCRYPTION_KEY` 都使用强随机值，不要复用。
- `.env` 放在运行用户自己的目录，例如 `$HOME/.jm-manga/.env`，权限建议 `0600`，不要随 release 同步。
- 默认数据目录是 `$HOME/.jm-manga`；如果要放到其它磁盘，可用 `DB_PATH` 和 `CACHE_DIR` 覆盖，并确保运行用户拥有写权限。
- 如果需要 Web 端，先构建 `./scripts/build.sh web`，后端会从 `WEB_DIR` 服务静态文件。

Caddy 示例：

```Caddyfile
jm.example.com {
    reverse_proxy 127.0.0.1:8000
}
```

Nginx 示例：

```nginx
server {
    listen 443 ssl http2;
    server_name jm.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Server Environment Variables

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `JM_PASSWORD_ENCRYPTION_KEY` | 空 | JM 密码落盘加密密钥。保存 JM 账号密码并支持 cookies 失效后重登时建议配置。 |
| `CLIENT_IMPL` | `api` | JM 客户端实现，当前支持 `api` 或 `html`。 |
| `JM_DOMAIN_LIST` | 空 | JM 域名列表覆盖配置，留空使用默认策略。 |
| `PROXY` | 空 | 后端访问 JM 时使用的代理地址。 |
| `API_TOKEN` | 空 | 客户端调用受保护 API 的 Bearer Token。公网必须配置。 |
| `HOST` | `0.0.0.0` | 后端监听地址。公网反代建议设为 `127.0.0.1`。 |
| `PORT` | `8000` | 后端监听端口。 |
| `ENV` | `development` | 运行环境标记，可设为 `production`。 |
| `LOG_LEVEL` | `INFO` | 日志级别，例如 `DEBUG`、`INFO`、`WARNING`。 |
| `NETWORK_MODE` | `auto` | 网络模式：`lan`、`public`、`auto`。公网建议显式 `public`。 |
| `MDNS_ENABLED` | `true` | 是否启用局域网 mDNS 广播。公网模式会自动关闭。 |
| `ENABLE_METRICS` | `false` | 是否启用 `/metrics` Prometheus 文本指标。 |
| `WEB_DIR` | `./web` | FastAPI 服务 Flutter Web 产物的目录。 |
| `DB_PATH` | `$HOME/.jm-manga/app.db` | SQLite 数据库文件路径，可用环境变量覆盖。 |
| `CACHE_DIR` | `$HOME/.jm-manga/cache` | 图片和封面缓存目录，可用环境变量覆盖。 |
| `JM_CONCURRENCY` | `5` | 访问 JM 数据接口的并发上限。 |
| `IMAGE_CONCURRENCY` | `3` | 图片下载/解码并发上限。 |
| `IMAGE_TOKEN_TTL` | `3600` | 图片签名 URL 有效期，单位秒。 |
| `IMAGE_SIGN_SECRET` | 空 | 图片代理签名密钥。公网必须配置。 |

网络模式说明：

- `lan`：局域网模式。允许 `API_TOKEN` 为空，可启用 mDNS。
- `public`：公网模式。要求 `API_TOKEN` 和 `IMAGE_SIGN_SECRET` 非空，并关闭 mDNS。
- `auto`：根据 `HOST` 推断。`127.0.0.1`、`localhost`、私网地址按 `lan`；`0.0.0.0` 或公网地址按 `public`。

## Common Commands

版本管理：

```bash
cat VERSION
./scripts/sync-version.sh
```

根目录 `VERSION` 是应用版本源头，格式为 `x.y.z` 或 `x.y.z-prerelease`，不要写 Flutter 的 `+<build-number>`。后端运行时版本来自 `server/src/jm_manga_server/version.py`，Python 包版本来自 `server/pyproject.toml`，Flutter App 版本来自 `ui/pubspec.yaml`。修改 `VERSION` 后运行 `./scripts/sync-version.sh` 同步；Flutter 的 `+<build-number>` 保留在 `ui/pubspec.yaml` 中。

后端开发：

```bash
cd server
uv sync
uv run fastapi dev src/jm_manga_server/main.py
uv run jm-manga-server
uv run jm-manga-server init-env --path .env --force
../scripts/update-jmcomic.sh
```

后端检查：

```bash
cd server
uv run ruff check src tests
uv run ruff format --check src tests
uv run pytest tests -q
```

Flutter 开发：

```bash
cd ui
flutter pub get
flutter run
flutter analyze --fatal-infos
flutter test
```

当前本机环境中 `flutter test` 可能因 Flutter test shell WebSocket 503 无法启动；`flutter analyze --fatal-infos` 可正常运行。

统一构建：

```bash
./scripts/build.sh server      # 后端 Python 源码包
./scripts/build.sh server-web  # 后端 Python 源码包，并打包 Flutter Web
./scripts/build.sh web         # Flutter Web，打包到 build/，并复制到 server/web
./scripts/build.sh apk         # Android APK
./scripts/build.sh ios         # iOS app，要求 macOS + Xcode
./scripts/build.sh all
```

构建产物会根据应用、功能、版本、平台和模式命名，例如：

```text
build/jm-manga-server-source-v0.1.0-python.tar.gz
build/jm-manga-server-source-web-v0.1.0-python.tar.gz
build/jm-manga-flutter-web-v0.1.0+1-web-release.tar.gz
build/jm-manga-flutter-apk-v0.1.0+1-android-release.apk
build/jm-manga-flutter-unsigned-ipa-v0.1.0+1-ios-release.ipa
```

构建环境变量：

```bash
BUILD_MODE=release|debug|profile
IOS_EXPORT=unsigned-ipa|unsigned-app
WEB_BASE_HREF=/
WEB_SERVER_DIR=/path/to/server/web
SERVER_PLATFORM=python|linux-x64|macos-arm64|...
SERVER_INCLUDE_WEB=true|false
SERVER_BUILD_WEB=true|false
SERVER_WEB_SOURCE=/path/to/web
```

`./scripts/build.sh ios` 不使用本机签名，默认产出文件名带 `unsigned` 的 IPA。签名、Team、Provisioning Profile 留给后续手动或 CI 重签流程处理。

`scripts/update-jmcomic.sh` 会执行 `uv lock --upgrade-package jmcomic && uv sync`，用于在部署或构建前尝试更新到当前可解析的 JMComic 最新版本。更新后请跑后端测试再提交新的 `server/uv.lock`。

健康检查：

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/ready
```

带 token 调用受保护接口：

```bash
curl -H "Authorization: Bearer <API_TOKEN>" \
  http://127.0.0.1:8000/api/v1/server/cache
```

## Flutter Web / PWA Notes

```bash
./scripts/build.sh web
```

构建完成后：

- `build/jm-manga-flutter-web-*.tar.gz`：Web 构建包。
- `server/web/`：后端默认服务目录。
- 后端会对普通前端路由返回 `index.html`，不会覆盖 `/api/*`、`/health`、`/ready`、`/metrics`。
- Web 端默认使用当前页面的 origin 作为后端地址，不展示服务列表页；如果后端需要 `API_TOKEN`，首次访问会弹出 token 输入框。
- Web 端不展示日志页入口。

PWA 安装提醒：

- `localhost` / `127.0.0.1` 可以用于本机测试。
- 局域网 IP 的 HTTP 一般不能作为正式可安装 PWA。
- 生产或多设备使用建议 HTTPS。

## Data And Cache

服务端统计口径：

- 封面缓存：`CACHE_DIR/covers`
- 漫画图片缓存：`CACHE_DIR/images`
- 数据占用：只统计 `DB_PATH` 指向的 SQLite 文件，也就是 `app.db`

不要提交以下内容：

- `.env`
- `$HOME/.jm-manga/`
- `server/data/`
- `server/web/`
- `build/`
- 数据库、缓存、签名文件和本地构建产物

## More Docs

- [架构说明](docs/architecture.md)
- [部署指南](docs/deployment.md)
- [移动端打包](docs/building-mobile.md)
- [接口探测资料](docs/research/)
