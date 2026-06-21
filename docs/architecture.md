# 架构说明

## 总览

JM Manga 是个人使用的跨平台漫画阅读工具：

- 后端：FastAPI 代理 JMComic，负责搜索、分类、排行、详情、图片代理、收藏夹缓存和阅读进度。
- 前端：Flutter 客户端，负责服务选择、账号管理、列表浏览、详情页、阅读器和设置。
- 存储：后端 SQLite 保存阅读进度、收藏夹缓存、JM cookies 和可选加密密码；图片和封面缓存在文件系统。
- 部署：后端可以从源码目录或源码包运行，默认持久数据放在 `$HOME/.jm-manga`。

## 后端

主要模块：

- `main.py`：FastAPI app、lifespan、路由挂载、health/ready/metrics。
- `config.py`：环境变量配置。
- `auth.py`：API Token 校验，客户端使用 `Authorization: Bearer <API_TOKEN>`。
- `database.py`：SQLite async engine、session 和轻量迁移。
- `jm_client.py`：创建 jmcomic async client。
- `cookies.py`：JM 账号 cookies、当前账号和可选加密密码。
- `routers/`：业务 API。

核心 API 前缀为 `/api/v1`。

## 版本管理

根目录 `VERSION` 是应用版本源头，格式为 `x.y.z` 或 `x.y.z-prerelease`，不要包含 Flutter 的 `+<build-number>`。后端有两个需要同步的位置：

- `server/src/jm_manga_server/version.py`：运行时版本，用于 `/health` 和 mDNS。
- `server/pyproject.toml`：Python 包版本。

Flutter App 版本来自 `ui/pubspec.yaml`，格式为 `<VERSION>+<build-number>`；界面设置页通过 `package_info_plus` 读取这个版本。修改根 `VERSION` 后运行：

```bash
./scripts/sync-version.sh
```

## 鉴权边界

后端 API Token 是访问本服务的权限，不是 JM 账号密码。客户端通过标准 Bearer 头传递：

```http
Authorization: Bearer <API_TOKEN>
```

约定：

- `/health`：未鉴权，仅判断进程存活。
- `/ready`：未鉴权，用于部署 readiness。
- `/api/v1/*` 业务接口：按路由配置进行 API Token 校验。
- `/api/v1/images/{photo_id}/{image_index}`：使用图片签名 token，保护可分享图片 URL。
- `/api/v1/server/cache`：轻量受保护接口，可用于客户端验证服务 token 是否有效。

Flutter 连接服务时应先检查 `/health`，再请求已有受保护接口确认 API Token 正确。

## 数据与缓存

后端默认数据路径：

```text
$HOME/.jm-manga/app.db
$HOME/.jm-manga/cache/
```

也可以通过环境变量覆盖：

```text
DB_PATH=/path/to/app.db
CACHE_DIR=/path/to/cache
```

数据库和缓存不要放在 release / build 目录里，避免更新服务或清理构建产物时误删运行数据。

## 前端

主要目录：

- `lib/data/`：Dio client 与 repository。
- `lib/providers/`：Riverpod 状态，包含配置、服务、账号、列表和同步信号。
- `lib/screens/`：主页面、服务选择、搜索、排行榜、书架、详情、阅读器、设置。
- `lib/widgets/`：通用 UI 组件。
- `lib/models/`：API 数据模型。

敏感信息：

- 服务 API Token 保存在 `SecureStorage`。
- JM 账号密码保存在 `SecureStorage`。
- SharedPreferences 只保存非敏感配置或旧数据迁移入口。

## 阅读进度

阅读器根据当前可见页更新 `_currentIndex`，延迟同步到后端 `/api/v1/progress`。重新进入章节时，前端读取保存的 `image_index` 并尝试滚动到对应页。

阅读进度不依赖 JM 登录状态：

- Flutter 客户端生成稳定 `device_id`，通过 `X-Device-Id` 发送给后端。
- 未选择 JM 账号时，进度按 `device_id + album_id + photo_id` 归属。
- 选择 JM 账号时，进度按 `jm_username + album_id + photo_id` 归属，同时记录最后写入的 `device_id`。
- 查询登录账号进度时，后端返回当前账号记录以及当前设备的匿名记录，并按章节/本子取最新记录去重；不会按 `device_id` 匹配同设备上的其它 JM 账号记录。

## 部署模型

源码包解压后会得到：

```text
jm-manga-server-source-v<version>/
```

默认 `.env` 可以放在运行目录，也可以显式指定：

```text
uv run jm-manga-server init-env --path $HOME/.jm-manga/.env
```

默认持久数据位于：

```text
$HOME/.jm-manga
```
