# CODEBASE.md

本文件是 `app/lib/` 的代码导航，用于快速定位目录、关键文件与开发约定。

## 仓库顶层

```text
app/               Flutter 客户端源码与测试
scripts/           构建、版本同步、测试脚本
docs/              架构、构建、开发、设计文档
build/             构建产物（不提交）
repos/             参考源码（仅本地查阅，不打包）
VERSION            应用版本源头
```

## 应用入口

| 文件 | 职责 |
|------|------|
| `app/lib/main.dart` | 初始化日志、HTTP 覆盖、图片缓存清理，挂载 `ProviderScope` 与 `MaterialApp.router`。 |
| `app/lib/router.dart` | `go_router` 路由配置；所有页面路由集中在此。 |
| `app/lib/screens/main_screen.dart` | 底部导航主屏，管理 `HomeScreen` / `RankingsScreen` / `LibraryScreen` / `SettingsScreen` 四个 Tab。 |

## 目录速查

### `lib/core/`

应用级基础配置。

- `app_theme.dart` — Material 3 主题与 design tokens。
- `app_shadows.dart` — 通用阴影样式。

### `lib/models/`

纯数据模型与轻量值对象。

- `album.dart`
- `jm_account.dart`
- `reading_progress.dart`
- `reader_initial_data.dart`
- `app_version.dart` — semver 解析/比较。
- `app_update_info.dart` — GitHub release 数据模型。

### `lib/network/`

网络层。

- `jm/jm_client.dart` — JM 数据源 Dio client，封装签名、加密、域名选择、错误处理。
- `jm/jm_constants.dart` — token、常量、协议参数。
- `jm/jm_crypto.dart` — 请求签名与数据解密。
- `jm/jm_domain.dart` / `jm_domain_updater.dart` — 域名列表与可用域名探测。
- `jm/jm_image_service.dart` — 图片请求、重试、并发控制。
- `jm/jm_image_decoder.dart` — 图片解码（isolate）。
- `jm/jm_models.dart` — JM 接口原始 JSON 模型。
- `http_overrides*.dart` — 平台 HTTP 覆盖（处理无代理场景）。
- `proxy_config*.dart` — 代理配置（条件导入 io/stub）。

### `lib/data/`

业务 repository 与数据映射。

- `direct_manga_repository.dart` — 直连 JM 数据源的 repository 实现。
- `manga_repository.dart` — repository 抽象。
- `direct_manga_mapper.dart` — 接口模型 → 应用模型映射。
- `favorite_service.dart` — 收藏相关操作封装。

### `lib/local/`

基于 SQLite 的本地持久化。

- `local_database.dart` — SQLite 初始化与迁移。
- `local_manga_store.dart` — 漫画/收藏本地表操作。
- `local_manga_records.dart` — 阅读记录表操作。

### `lib/providers/`

Riverpod 状态管理。大多使用 `StateNotifier` + `StateNotifierProvider`。

| Provider | 职责 |
|----------|------|
| `account_provider.dart` | JM 账号登录状态与会话。 |
| `config_provider.dart` | 主题、语言、代理、日志级别等配置。 |
| `repository_provider.dart` | 按账号提供 `MangaRepository` 实例。 |
| `album_providers.dart` | 详情页、章节列表等异步状态。 |
| `library_signal_provider.dart` | 书架刷新信号。 |
| `app_sync_provider.dart` | 收藏同步触发。 |
| `search_history_provider.dart` | 搜索历史（SharedPreferences，30 条上限）。 |
| `app_update_provider.dart` | 应用内版本检测状态。 |
| `device_provider.dart` / `owner_key_provider.dart` | 设备 ID 与 key。 |

### `lib/screens/`

页面。

- `home_screen.dart` — 首页分类流。
- `rankings_screen.dart` — 排行榜。
- `library_screen.dart` — 书架。
- `album_detail_screen.dart` — 漫画详情。
- `reader_screen.dart` — 阅读器。
- `search_screen.dart` — 搜索与搜索历史。
- `settings_screen.dart` — 设置主页面（含版本检测入口）。
- `settings_advanced_screen.dart` — 高级选项。
- `custom_domain_settings_screen.dart` — 自定义 API/图片域名设置。
- `proxy_settings_screen.dart` — 代理设置。
- `cache_screen.dart` / `logs_screen.dart` / `faq_screen.dart` — 缓存、日志、FAQ。
- `category_screen.dart` — 分类详情。
- `main_screen.dart` — 底部导航壳。

### `lib/services/`

面向远端第三方服务的封装。

- `app_update_service.dart` — GitHub Releases API 请求。

### `lib/utils/`

工具类与横切关注点。

- `app_logger.dart` — 日志。
- `app_log_storage*.dart` — 日志本地存储。
- `custom_domain_utils.dart` — 自定义域名输入解析与校验。
- `secure_storage.dart` — 安全存储封装。
- `account_secret_store.dart` — 账号密码/会话统一清理。
- `error_mapper.dart` — 异常 → 用户可读文案。
- `image_cache_cleanup.dart` / `image_cache_lru_store.dart` — 图片缓存 LRU 与清理。
- `image_download.dart` — 图片下载工具。
- `favorite_action.dart` — 收藏/取消收藏动作封装。
- `top_toast.dart` — 顶部 Toast。
- `proxy_config*.dart` — 代理 Dio 配置（条件导入）。

### `lib/widgets/`

通用 UI 组件。

- `manga_cover_card.dart` — 漫画封面卡片。
- `pill_selector.dart` — 胶囊选择器。
- `error_placeholder.dart` — 错误占位图（含重试）。
- `loading_indicator.dart` — 加载指示。
- `animated_favorite_button.dart` — 收藏动画按钮。
- `animations/` — 入场动画工具。
- `app_dropdown.dart` / `pressable.dart` / `ranking_badge.dart` 等。

### `lib/l10n/`

- `app_en.arb` / `app_zh.arb` — ARB 源文件。
- `app_localizations*.dart` — `flutter gen-l10n` 生成文件。

## 关键约定

### 状态管理

- 全局/页面级状态优先使用 `StateNotifier` + `StateNotifierProvider`。
- Provider 命名：`xxxProvider` 对应 `StateNotifierProvider`，`xxxNotifier` 对应 `StateNotifier`。
- 配置类状态使用 `Freezed` 等价物？本项目当前使用普通 class + `copyWith`。

### 网络请求

- JM 接口统一通过 `JmClient`（Dio）发送，请求前自动签名，返回后自动解密。
- 代理配置在 `configProvider` 中读取，通过 `configureDioProxy` 应用到 Dio 实例。
- 自定义 API/图片域名以 `List<String>` 形式通过 `configProvider` 注入 `JmClient`；多个域名按顺序优先于内置/自动域名。
- 错误统一映射为用户可读文案：`mapErrorToUserMessage(error, l10n)`。

### 本地存储

| 数据 | 存储方式 |
|------|----------|
| 账号密码、会话凭证 | `SecureStorage` |
| 收藏、阅读进度 | SQLite（`local/`） |
| 主题、语言、代理、日志级别、搜索历史、图片缓存 LRU 元数据 | `SharedPreferences` |

### 路由

- 新增页面先在 `router.dart` 注册 `GoRoute`，再使用 `context.push('/path')` 跳转。
- `MainScreen` 通过 `tab`/`subTab` query 参数支持 deep link 到指定 Tab。

### 本地化

- 新文案同时添加 `app_en.arb` 与 `app_zh.arb`。
- 修改后运行 `flutter gen-l10n` 重新生成 Dart 文件。

### 测试

- `test/` 目录与 `lib/` 镜像对应。
- 单元测试：模型解析/比较、服务请求解析。
- Provider 测试：使用 fake service 注入 `StateNotifier`。
- Widget 测试：渲染关键页面。
- 运行：`cd app && NO_PROXY=127.0.0.1,localhost flutter test` 或 `./scripts/test-flutter.sh`。

## 添加新功能建议路径

1. **模型**：在 `lib/models/` 定义数据模型。
2. **服务/数据源**：在 `lib/network/` 或 `lib/services/` 添加远端请求。
3. **状态**：在 `lib/providers/` 添加 Notifier 与 Provider。
4. **UI**：在 `lib/screens/` 添加页面，在 `lib/widgets/` 提取可复用组件。
5. **路由**：在 `lib/router.dart` 注册。
6. **本地化**：更新 `lib/l10n/*.arb` 并 `flutter gen-l10n`。
7. **测试**：在 `test/` 对应目录补充测试。
8. **文档**：如改动了架构、构建或约定，更新 `docs/ARCHITECTURE.md`、`docs/DEVELOPMENT.md` 或本文件。

## 相关文档

- `docs/ARCHITECTURE.md` — 整体架构与数据流。
- `docs/DEVELOPMENT.md` — 开发环境、构建、测试命令。
- `docs/BUILDING-MOBILE.md` — 移动端打包说明。
- `docs/DESIGN.md` — 设计系统与视觉规范。
