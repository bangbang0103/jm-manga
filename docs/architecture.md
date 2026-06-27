# 架构说明

## 总览

JM Manga 是个人使用的移动端 JM 漫画阅读应用，目前仅支持 iOS 与 Android。

- **前端**：Flutter 客户端直接请求数据源接口与图片服务。
- **本地存储**：`SecureStorage` 保存账号凭据和会话凭证；SQLite 保存收藏与阅读进度；SharedPreferences 保存代理、日志级别、主题、语言、图片缓存 LRU 元数据等非敏感配置。搜索历史当前未持久化。
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
- `lib/local/`：本地 records 管理（基于 SQLite）。
- `lib/l10n/`：本地化 ARB 与 generated 文件。
- `lib/providers/`：Riverpod 状态，包含账号、配置、列表和同步信号。
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
