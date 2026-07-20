# 平台扩展评估与实施计划：横屏适配 + Windows/macOS

> 性质：评估与决策记录（2026-07-18 访谈锁定）。**已全部实施**（同日）：桌面基建、响应式 UI、阅读器点击翻页均已落地，`flutter analyze --fatal-infos` 与 359 项测试全绿，macOS release 冒烟构建与脚本打包链路验证通过。
> 遗留：详情页（album_detail，NestedScrollView + SliverAppBar 结构复杂）宽屏未做限宽，作为后续优化项；Windows 端仅做了脚本与代码准备，未在真机构建验证。

## 决策记录

| 决策点 | 结论 |
| --- | --- |
| Web 端 | **不做**。与直连架构冲突，理由见下文「Web 排除理由」 |
| 横屏深度 | 深度适配缩减版：响应式网格 + 内容限宽 + NavigationRail + 阅读器点击翻页；**不做 master-detail 双栏** |
| 网格列数 | 按宽度自适应（`MaxCrossAxisExtent`），原 2–4 列设置改为密度预设 |
| 阅读器 | 双模式：竖向滚动（现状）+ **点击翻页**（单页）；不做双页模式，不随旋转自动切换 |
| 桌面平台 | Windows + macOS，本地自用并接入发布脚本；不做 Linux |
| macOS 签名 | ad-hoc / 不签名，脚本预留 `CODESIGN_IDENTITY` 钩子 |
| 双栏 | 不做（用户在深度适配后明确砍掉） |

## 现状事实（代码探索结论）

- **方向锁**：三层均无锁定。`app/android/.../AndroidManifest.xml` 无 `screenOrientation`；`app/ios/Runner/Info.plist` 四方向全开；Dart 侧无 `SystemChrome`。横屏今天就能转，只是零适配。
- **网格列数**：`app/lib/providers/config_provider.dart` 的 `gridColumns`（2–4，默认 3，存 prefs）与屏幕宽度无关。5 处 `SliverGridDelegateWithFixedCrossAxisCount`：`search_screen.dart:294`、`library_screen.dart:554`、`category_screen.dart:167`、`rankings_screen.dart:478/553`，共用 wrapper `widgets/animations/staggered_grid.dart`。
- **阅读器**：`reader_screen.dart` 仅竖向 ListView 滚动，进度以 `image_index` 记录（`utils/reader_progress.dart`）。
- **条件导入**：已有 `_stub/_io` 模式覆盖 `http_overrides`、`proxy_config`、`app_log_storage`、`jm_image_service`、`image_cache_cleanup`，桌面天然走 `_io` 分支。
- **Runner**：`app/windows|macos|web|linux/` 本地存在但被根 `.gitignore`（第 63–66 行）忽略，属未维护残留。残留 macOS runner 的 entitlements 已含 `com.apple.security.network.client` 与 `keychain-access-groups`（bundle 前缀 `com.jmmanga.app`）。
- **sqflite**：`local/local_database.dart`、`local/local_manga_records.dart` 直连 sqflite，桌面需切 `databaseFactoryFfi`；`sqflite_common_ffi` 已在 dev_dependencies（测试用）。
- **脚本**：`scripts/build-flutter.sh`（apk|ios|all，产物 + sha256）、`scripts/release.sh`（版本一致性校验 + 清理 + 汇总）、`scripts/sync-version.sh`（VERSION → pubspec/server）。无 CI（`.github/workflows/` 不存在）。
- **导航**：`main_screen.dart` 为手写 IndexedStack + BottomNavigationBar（4 tab，无 router shell）。

## 改动清单

### A. 横屏适配（iOS/Android 既有平台）

无需动任何原生配置，工作全在 UI 层。

1. **响应式网格**：5 处网格改为 `SliverGridDelegateWithMaxCrossAxisExtent`（集中在 `staggered_grid.dart` 改造）；`gridColumns` 设置改为密度预设：紧凑 / 标准 / 宽松 ≈ maxCrossAxisExtent 100 / 150 / 240（手机宽度下约 4 / 3 / 2 列，与旧列数观感一致）；旧 pref 迁移映射：2→宽松、3→标准、4→紧凑。
2. **NavigationRail**：`main_screen.dart` 在宽屏（断点 ~840dp）下改为 `Row { NavigationRail + Expanded(body) }`，窄屏保持 BottomNavigationBar 不变。
3. **内容限宽**：设置、FAQ、日志、代理/域名、缓存、详情等表单/文本页在宽屏下限宽居中（内容带 ~840dp）。
4. **阅读器点击翻页**：新增阅读模式 pref（竖向滚动 / 点击翻页）+ `reader/reader_toolbar.dart` 快捷切换并记住选择。点击翻页为单页 PageView：每屏一张图、`BoxFit.contain`（横屏自然按高度适配、两侧留空，无需额外横屏逻辑）；点击左半屏上一页、右半屏下一页（LTR）、中间呼出/隐藏工具栏，保留左右滑动手势。进度直接用 `image_index` 作页码，无双页换算，resume 复用现有逻辑。复用现有预加载机制。
5. 附带项：`main_screen.dart` 的 `_confirmExit` 退出确认是移动端语义，桌面端跳过。

### B. 桌面 Windows + macOS

1. **Runner 重建**：`flutter create --platforms=windows,macos .` → 补回 macOS `Release.entitlements` 的 `network.client`（模板默认没有，漏了 release 包无网络，经典坑）→ 根 `.gitignore` 删除 `app/windows/`、`app/macos/` 两行（web/linux 保持忽略）→ 提交 runner。前置条件：Windows 需 VS Build Tools，macOS 需 Xcode。runner 保持 Flutter 模板的无团队签名配置；review 后移除了 `keychain-access-groups`（该 entitlement 需要开发团队才能构建，与 ad-hoc 默认冲突）。
2. **sqflite 桌面化**：`sqflite_common_ffi` 移到 dependencies；Windows 的 sqlite3 原生库由 `sqlite3` 3.x 的 native-assets 构建钩子（`hook/build.dart`）源码编译，macOS 走 sqflite 原生插件。`sqlite3_flutter_libs` 自 0.6.0+eol 起为空操作包，官方建议迁移到 `sqlite3` 3.x 后移除，review 后已从依赖中删除。`local_database.dart` 的 `_open()` 按 `defaultTargetPlatform` 设置 `databaseFactory = databaseFactoryFfi`。
3. **依赖实测**：flutter_secure_storage（macOS 用文件型 keychain：`useDataProtectionKeyChain: false`，ad-hoc 签名下无需 keychain entitlement）、share_plus、url_launcher、package_info_plus；`app_update_provider` 更新检查面向 APK，桌面端需禁用或扩展。
4. **发布脚本**：
   - `build-flutter.sh` 增加 `build_windows` / `build_macos`，仿 `build_ios` 的宿主平台检查（Windows 包只能在 Windows 构建；`detect_host_platform` 可复用），产物 zip + sha256，命名沿用 `jm-manga-<platform>-v<version>-...` 风格。
   - `release.sh` 增加 `desktop|windows|macos` target，扩展清理 pattern 与末尾汇总 grep；版本校验不动（pubspec 已是事实源）。
   - `sync-version.sh` 不动。
5. **签名**：macOS ad-hoc（`flutter build macos` 默认 sign-to-run-locally，本机无感，他机右键打开绕过 Gatekeeper），脚本预留 `CODESIGN_IDENTITY` 钩子；Windows zip 免安装。
6. **验证**：`flutter analyze --fatal-infos`、`flutter test`（ffi 测试基础已在）、`bash -n` 全部脚本、双平台实机构建冒烟。

### C. Web 排除理由（存档）

与 commit `7eb209d`「移除 server 层、直连 JM」的决策正面冲突：浏览器直连 JM API = CORS 拒绝；图片 CDN 有防盗链且需自定义解码（`network/jm/jm_image_service_stub.dart` 对 web 直接 throw `UnsupportedError`）。另有 4 个文件直引 `dart:io`（`cache_screen.dart`、`image_download.dart`、`local_manga_records.dart`、`jm_image_cache.dart`），sqflite 无 web 实现。重启 web 的前提 = 恢复代理层 + 存储抽象 + 图片链路重写，三个方向中成本最高。

### D. 文档更新（实施时）

- `AGENTS.md`：平台政策由「仅 Android APK + iOS 未签名 IPA」改为四平台。
- `docs/building-mobile.md`：扩充或新增桌面构建文档。
- `README.md` / `README.en.md`：平台支持矩阵。
- `docs/ARCHITECTURE.md`：响应式布局断点、阅读模式。

## 实施顺序

1. **桌面基建**（runner 重建 + sqflite_ffi + 发布脚本）：无 UI 风险，先行，为响应式提供桌面验证场。
2. **响应式 UI**（网格 + 限宽 + NavigationRail）：横屏 / 桌面共同受益。
3. **阅读器点击翻页**：双模式 + 进度复用，风险最低，放最后。

## 主要风险

- `gridColumns` 旧设置迁移（映射密度预设，注意 clamp 边界）。
- macOS runner 重建时 entitlements 遗漏 → release 包无网络。
- Windows 包漏带 sqlite3 原生库（由 `sqlite3` 3.x 的 native-assets 构建钩子随构建编译打包，需真机构建验证）。
- 桌面端更新检查误报（`app_update_provider` 面向 APK）。
