# 架构说明

## 总览

JM Manga 是个人使用的移动端 JM 漫画阅读应用，目前仅支持 iOS 与 Android。

- **前端**：Flutter 客户端直接请求数据源接口与图片服务。
- **可选自托管加速服务**：`server/` 目录下是一个基于 FastAPI + jmcomic 的 Python 服务。用户可将其部署在 VPS/NAS/本地，然后在 Flutter 客户端的「自定义域名」中把 API 域名与图片域名指向该服务，以获得缓存、线路优化等加速能力。该服务完全可选，不启用时 Flutter 客户端仍直连官方。
- **本地存储**：`SecureStorage` 保存账号凭据和会话凭证；SQLite 保存收藏与阅读进度；SharedPreferences 保存代理、日志级别、主题、语言、搜索历史、图片缓存 LRU 元数据等非敏感配置。
- **发布**：直接构建 APK/IPA 后安装即可使用。



## 版本管理

根目录 `VERSION` 是应用版本源头，格式为 `x.y.z` 或 `x.y.z-prerelease`，不要包含 Flutter 的 `+<build-number>`。`app/pubspec.yaml` 使用 `<VERSION>+<build-number>` 格式，界面设置页通过 `package_info_plus` 读取。修改根 `VERSION` 后运行：

```bash
./scripts/sync-version.sh
```

该脚本仅同步 Flutter 版本号。

## 前端

主要目录：

- `lib/core/`：主题等应用级基础配置。
- `lib/data/`：repository、数据映射与业务服务（如收藏服务）。
- `lib/models/`：数据模型。
- `lib/network/`：网络层，包含 HTTP 代理覆盖、代理配置、错误映射，以及 `network/jm/` 子目录下的 JM 数据源 client、常量、加密、域名、图片服务与解码。
- `lib/services/`：面向远端第三方服务的封装（如 GitHub Releases 更新检测）。
- `lib/local/`：本地 records 管理（基于 SQLite）。
- `lib/l10n/`：本地化 ARB 与 generated 文件。
- `lib/providers/`：Riverpod 状态，包含账号、配置、列表、同步信号、搜索历史与应用更新检测。
- `lib/screens/`：主页面、搜索、排行榜、书架、详情、阅读器、设置、缓存、日志、代理设置、高级选项等。
- `lib/utils/`：日志、存储、缓存清理、图片下载、收藏动作、Toast 等工具。
- `lib/widgets/`：通用 UI 组件。
- `lib/router.dart`：go_router 路由配置。

运行模式：

- 应用固定直连 JM 数据源接口与图片服务，无后端服务器选择入口。
- 网络层支持在 设置 > 高级选项 > 代理设置 中配置 HTTP / SOCKS5 代理。

敏感信息：

- 账号密码保存在 `SecureStorage`。
- 会话凭证保存在 `SecureStorage`。
- SharedPreferences 保存非敏感配置（代理、日志级别、主题、语言、图片缓存 LRU 元数据等）。
- 收藏与阅读进度保存在 SQLite。
- 删除账号时由 `AccountSecretStore` 统一清理 password 与 session cookie，并 `invalidate` repository provider 释放内存中的旧客户端实例。

## 收藏同步

收藏数据保存在本地（`LocalMangaStore` + `LocalMangaRecords`），并通过 `DirectMangaRepository.syncFavorites(full: true)` 与远端收藏列表同步：

- 手动同步时一次性拉取远端全部收藏。
- 与本地 `pendingAdd` / `pendingRemove` 做 diff：
  - `pendingAdd` 且远端不存在时才调用 `toggleFavorite`；已存在则直接标记为 `synced`。
  - `pendingRemove` 且远端存在时才调用 `toggleFavorite`；不存在则直接删除本地记录。
- 合并后的列表整表替换本地收藏，失败的 pending 项保留原状态，并提示用户部分同步失败。
- 登录（`loginToJm`）只完成账号登录与凭证持久化，不再自动合并或全量同步收藏。
- 后台定时同步已取消，收藏同步完全由用户手动触发。

## 阅读进度

阅读器根据当前可见页更新 `_currentIndex`，并保存到本地 SQLite。重新进入章节时，前端读取保存的 `image_index` 并尝试滚动到对应页。

进度归属：

- 按 `jm_username + album_id + photo_id` 归属（已登录账号）。
- 未选择 JM 账号时，按 `device_id + album_id + photo_id` 归属。

## 应用更新检测

- `AppUpdateService` 调用 GitHub Releases API（`repos/{owner}/{repo}/releases/latest`）获取最新 release。
- `AppUpdateNotifier` 在 `MainScreen` 初始化时自动静默检测，并在设置页版本号入口展示红点提示。
- 版本比较按 semver（`major.minor.patch`）进行，忽略 Flutter build number。
- 检测失败时自动检测静默；手动点击版本号失败时通过 `TopToast` 提示。
- 检测到新版本后点击进入详情页，展示 release notes 并提供“立即下载”按钮跳转 GitHub Release 页面。

## 自定义域名

- 用户在 `Settings → Advanced → Custom Domain` 中分别设置多个 API 域名与图片域名，每行一个。
- 输入支持域名、`IP:port` 或完整 URL；缺失 scheme 时自动补全 `https://`。
- 配置以 JSON 列表持久化到 `SharedPreferences`，通过 `configProvider` 注入 `JmClient`。
- `JmClient` 按输入顺序将所有自定义域名主机排在域名列表前部，依次优先尝试；失败时按原有机制回退到自动更新或内置域名。
- 自定义域名可指定 `http` 与非标准端口，`JmImageService` 在回退到内置图片 CDN 时会切回 `https`。

## 图片与缓存

- 图片通过 `JmImageService` 请求图片服务，支持重试与并发限制。
- 封面和阅读页图片缓存到应用私有缓存目录。
- 正文图解码已通过 `compute` 在 isolate 中执行；封面图直接缓存原字节。
- 图片缓存支持 LRU 容量限制与智能清理：封面图上限 256 MB、14 天未访问自动清理；正文图上限 512 MB、7 天未访问自动清理。应用冷启动时异步执行清理，不阻塞 UI。

## 设计约束

- 当前仅支持 iOS 与 Android。
- 数据源接口的 token、版本、域名和加密协议可能变化，相关常量集中在 `app/lib/jm/` 管理。
- `repos/` 目录下的参考源码仅用于本地查阅，不作为应用依赖打包。
- 不提交真实 `.env`、数据库、缓存、签名文件或构建产物。

## 数据目录

默认持久数据位于应用私有目录，不放在 `build/` 或 release 目录内，避免清理构建产物时误删。

## 可选自托管加速服务

`server/` 提供可选的独立后端服务，用于加速 Flutter 客户端对 JM 官方接口与图片 CDN 的访问。

- **技术栈**：Python 3.11+、FastAPI、uvicorn、jmcomic（async client）、uv。
- **部署形态**：用户自托管（VPS/NAS/本地），提供 `Dockerfile`、`docker-compose.yml` 与裸 Python 启动脚本 `run.sh`。
- **接入方式**：Flutter 客户端通过现有的「自定义域名」功能，将 API 域名与图片域名同时指向 server。Flutter 侧无需任何代码改动。
- **接口兼容**：
  - API 路由完全按官方路径映射（`/search`、`/album`、`/chapter`、`/categories/filter`、`/favorite`、`/login` 等）。
  - `/chapter_view_template` 透传原始 HTML，供 Flutter 提取 `scramble_id`。
  - 图片路由完全按官方 CDN 路径映射（`/media/albums/...`、`/media/photos/...`）。
- **内部实现**：
  - API 请求由 jmcomic `AsyncJmApiClient` 重放；返回数据用 Flutter 客户端的 timestamp 重新加密，使 Flutter 端可以正常解密。
  - 图片请求透明回源 JM CDN，不解码，直接返回原始字节。
  - Cookie 由 Flutter 客户端透传；server 不保存用户密码，也不共享 jmcomic session。每个 API / login / scramble 请求都会从基础配置深拷贝出独立的 jmcomic client 并注入当前请求的 Cookie，避免请求间串号。图片下载使用独立的 `aiohttp.ClientSession` 复用连接。
  - `/login` 由 server 代为登录后将 `Set-Cookie` 返回给 App。
- **缓存策略**：
  - API 响应做 60s 内存 LRU 缓存；`/favorite`、`/login` 等有状态接口不缓存。
  - 图片做磁盘 LRU 缓存，默认上限 50GB，缓存键忽略 `scramble_id` query 参数。
- **配置**：`config.yml` 与环境变量（前缀 `JM_SERVER_`）均可；详情见 `server/README.md`。
  - 新增 `public_base_url`：用于 `/chapter_view_template` 中 `imghost` 的改写，方便反代场景。未配置时会依次尝试 `X-Forwarded-Proto` / `X-Forwarded-Host`、`Forwarded` header，最后回退到请求自身的 scheme 与 Host。
  - Docker 构建已固定 uv 版本并复制 `uv.lock` 安装，保证依赖可复现。
- **测试**：`server/tests/` 包含单元测试与基于 mock jmcomic client 的集成测试，运行 `uv run pytest`。
