# 架构说明

## 总览

JM Manga 是个人使用的 JM 漫画阅读应用，支持 iOS 与 Android；Windows 与 macOS 桌面端处于 Alpha 阶段。

- **前端**：Flutter 客户端直接请求数据源接口与图片服务。
- **本地存储**：`SecureStorage` 保存账号凭据和会话凭证；SQLite 保存收藏与阅读进度；SharedPreferences 保存代理、日志级别、主题、语言、搜索历史、图片缓存 LRU 元数据等非敏感配置。
- **发布**：移动端构建 APK 与未签名 IPA，桌面端构建 Windows/macOS zip（ad-hoc 签名），安装即可使用。



## 版本管理

根目录 `VERSION` 是应用版本源头，格式为 `x.y.z` 或 `x.y.z-prerelease`，不要包含 Flutter 的 `+<build-number>`。`app/pubspec.yaml` 使用 `<VERSION>+<build-number>` 格式，界面设置页通过 `package_info_plus` 读取；server 的 Python 包版本使用同一个 `VERSION`。修改根 `VERSION` 后运行：

```bash
./scripts/sync-version.sh
```

该脚本会同步 Flutter 版本号、server `pyproject.toml` 和 `uv.lock` 中的本地包版本。

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

响应式与阅读模式：

- 宽屏（≥840dp，横屏/桌面窗口）下主导航由 BottomNavigationBar 切换为 NavigationRail；表单/文本类页面用 `MaxWidthCenter`（内容带 840dp）限宽居中。
- 封面网格列数随宽度自适应（`coverGridDelegate` + `SliverGridDelegateWithMaxCrossAxisExtent`），密度预设（紧凑/标准/宽松）保存在配置中，由旧的 2–4 列设置自动迁移。
- 阅读器支持竖向滚动与点击翻页两种模式（`readerMode` 配置，工具栏可切换）；点击翻页为单页 PageView（左/右 30% 点击区翻页，中间呼出工具栏），两种模式进度都以 `image_index` 记录。
- 桌面端跳过启动时的更新检查（更新包面向 APK）与退出确认弹窗。

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

## 自定义域名（BETA，入口已隐藏）

> 该功能处于 BETA 阶段。配套的自托管加速服务已于 v0.2.5 移除，设置页入口同时隐藏；
> 底层配置能力保留，已设置过自定义域名的用户配置仍然生效。

- 用户原在 `Settings → Advanced → Custom Domain (BETA)` 中分别设置多个 API 域名与图片域名，每行一个；页面路由 `/settings/custom-domain` 保留，仅入口 ListTile 被移除。
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

- 支持 iOS、Android、Windows 与 macOS；明确不支持 Linux 与 Web。
  Windows 侧 SQLite 走 `sqflite_common_ffi`，sqlite3 原生库由 `sqlite3` 3.x 的 native-assets 构建钩子随构建从源码编译（无需预置 sqlite3.dll）；iOS/Android/macOS 用 sqflite 原生插件。
- 数据源接口的 token、版本、域名和加密协议可能变化，相关常量集中在 `app/lib/network/jm/` 管理。
- `repos/` 目录下的参考源码仅用于本地查阅，不作为应用依赖打包。`repos/` 已被 .gitignore 忽略、不入库，新克隆中不存在；如需参考请自行克隆上游 [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python) 与 [JMComic-qt](https://github.com/tonquer/JMComic-qt)。
- 不提交真实 `.env`、数据库、缓存、签名文件或构建产物。

## 数据目录

默认持久数据位于应用私有目录，不放在 `build/` 或 release 目录内，避免清理构建产物时误删。
