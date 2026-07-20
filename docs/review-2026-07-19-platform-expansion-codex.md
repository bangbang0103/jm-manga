# 代码 Review：横屏适配与 Windows/macOS 平台扩展（Codex）

日期：2026-07-19

## 结论

整体实现方向合理，响应式布局、阅读模式、SQLite 桌面适配和构建脚本的职责划分都比较清晰。不过，当前改动不建议直接提交：macOS 签名链路有两处高优先级问题，旧网格偏好的迁移方向也存在明确错误。分页阅读器还缺少空章节防御和模式切换边界处理。

建议先处理本文的 P1 问题，再补足分页阅读器与宽屏导航的针对性测试。

## 审查范围

本次审查覆盖当前工作区的未提交改动，主要包括：

- Windows/macOS Flutter Runner 与桌面发布脚本；
- SQLite 在 Windows 上切换到 `sqflite_common_ffi`；
- NavigationRail、内容限宽和响应式封面网格；
- 阅读器滚动/点击翻页双模式；
- 配置迁移、本地化、测试与相关文档。

本次只进行审查和验证，没有修改业务代码。

## P1：提交前应修复

### 1. macOS Runner 写死了本机开发团队

位置：[`app/macos/Runner.xcodeproj/project.pbxproj`](../app/macos/Runner.xcodeproj/project.pbxproj)

Runner 的 Debug、Profile、Release 配置均写入了本机 `DEVELOPMENT_TEAM`，并强制使用 `Apple Development` 身份。这不是 Flutter macOS 模板的默认配置，也与脚本和文档声称的“默认 ad-hoc 签名”不一致。

实际检查当前 Release 产物时，`codesign` 显示它带有开发团队标识，而不是 ad-hoc 签名。其影响包括：

- 没有该团队证书的开发机或发布机无法稳定复现构建；
- 产物签名策略依赖本地开发者账号，违背仓库不提交本地签名配置的原则；
- README 中“解压后右键打开”的分发说明与实际产物不完全一致。

建议恢复 Flutter 模板的无团队配置，移除 Runner target 中的本机 `DEVELOPMENT_TEAM` 和显式 `Apple Development` 身份。需要正式签名时，应由显式发布参数或独立签名流程注入身份。

### 2. `CODESIGN_IDENTITY` 重签步骤会剥离 entitlement

位置：[`scripts/build-flutter.sh`](../scripts/build-flutter.sh) 的 `build_macos()`。

当前逻辑：

```bash
codesign --force --deep --sign "${CODESIGN_IDENTITY}" "${app_dir}"
```

该命令没有提供或安全保留 entitlement。为验证其行为，本次将现有 Release app 复制到临时目录并以相同参数重新签名；重签前可读取到以下 entitlement：

- `com.apple.security.app-sandbox`；
- `com.apple.security.network.client`；
- `keychain-access-groups`；
- application/team identifier。

重签后，`codesign -d --entitlements -` 不再返回任何 entitlement。这样会移除 `flutter_secure_storage` 在 macOS 上要求的 Keychain Sharing 配置，也会改变应用的 sandbox 与网络权限模型。

不建议直接在最终 app 上使用裸 `codesign --deep`。优先方案是让 Xcode 在构建阶段用目标身份和正确 entitlement 完成签名；如果必须后处理签名，则需要为目标签名团队生成匹配的 entitlement，并正确处理主程序、Framework 与嵌套组件，不能简单复用未展开的 `$(AppIdentifierPrefix)` 文件。

### 3. 旧 `gridColumns` 到 `GridDensity` 的迁移方向反了

位置：[`app/lib/providers/config_provider.dart`](../app/lib/providers/config_provider.dart) 的 `GridDensityLayout.fromLegacyColumns()`。

当前定义为：

- `compact`：`maxCrossAxisExtent = 160`，封面更小、同宽下列数更多；
- `standard`：`maxCrossAxisExtent = 200`；
- `loose`：`maxCrossAxisExtent = 240`，封面更大、同宽下列数更少。

因此，旧设置的视觉语义应当是：

- 旧 2 列 → `loose`；
- 旧 3 列 → `standard`；
- 旧 4 列 → `compact`。

当前实现使用 `2 → compact`、`4 → loose`，会反转升级用户的显示偏好。新增测试 `migrates legacy gridColumns to density` 也把错误映射固化成了绿色断言，修复实现时需要同步修改测试。

另外需要产品层面确认 `standard = 200` 是否是预期默认值：在常见手机宽度上它通常会显示 2 列，而旧默认是 3 列。即使迁移映射修正，没有保存旧 key 的用户也可能看到明显的默认布局变化。

## P2：建议本次一并处理

### 4. 空章节会使分页阅读器崩溃

位置：[`app/lib/screens/reader/paged_reader_view.dart`](../app/lib/screens/reader/paged_reader_view.dart) 的 `initState()`。

```dart
_currentPage = widget.targetIndex.clamp(0, widget.imageUrls.length - 1);
```

当 `imageUrls` 为空时，上界为 `-1`，`clamp(0, -1)` 会抛出 `ArgumentError`。原滚动模式可以容忍空列表，`reader_progress.dart` 也专门处理了 `pageCount <= 0`，分页模式应保持相同的防御能力。

建议由 `ReaderScreen` 统一展示空章节状态，或者让 `PagedReaderView` 明确处理空列表，同时保护 `_goToPage()` 中的同类计算。

### 5. 切回滚动模式时没有重置 resume 尝试次数

位置：[`app/lib/screens/reader_screen.dart`](../app/lib/screens/reader_screen.dart) 的 `_toggleReaderMode()`。

滚动模式的断点恢复最多尝试 20 帧。如果初次恢复已经消耗完 `_resumeAttempts`，用户从分页模式切回滚动模式后，即使设置了 `_needsScrollJump`，`_resumeToIndex()` 也不会再次尝试，页面会停在错误位置。

建议设置 `_needsScrollJump = true` 时同时执行：

```dart
_resumeAttempts = 0;
```

### 6. 快速连续点击可能少翻一页

`PagedReaderView._goToPage()` 只有在 `onPageChanged` 回调时才更新 `_currentPage`。150ms 动画结束前连续点击两次，第二次仍会基于旧页码计算目标，因此两次点击可能只前进一页。

这是轻微 UX 问题，可以通过记录目标页、动画期间排队输入，或在发起动画时更新本地目标状态解决。

## 依赖与文档整洁度

### `sqlite3_flutter_libs` 已经是无操作的废弃依赖

位置：[`app/pubspec.yaml`](../app/pubspec.yaml)。

锁定的 `sqlite3_flutter_libs 0.6.0+eol` 自身 README 明确说明：该版本开始不再执行任何操作，使用 `sqlite3 3.x` 后应用应移除它。当前 Windows SQLite 原生库实际由 `sqlite3 3.x` 的 native-assets/build hook 提供，而不是由这个包携带 DLL。

因此建议：

- 删除 `sqlite3_flutter_libs` 直接依赖；
- 保留 `sqflite_common_ffi` 运行时依赖；
- 修正 `docs/ARCHITECTURE.md` 与 `docs/platform-expansion-plan.md` 中“`sqlite3_flutter_libs` 自带/兜底 sqlite3.dll”的描述。

### 文档仍有多处平台事实不一致

- [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) 开头仍写“目前仅支持 iOS 与 Android”，发布说明也只提 APK/IPA；
- [`README.en.md`](../README.en.md) 仍将项目描述为 iOS/Android mobile app，安装包列表没有桌面 zip；
- [`app/README.md`](../app/README.md) 仍写只支持 Android/iOS；
- [`docs/README.md`](README.md) 仍把 `building-mobile.md` 描述为 Android/iOS 打包指南；
- `docs/platform-expansion-plan.md` 记录“345 项测试”，当前实际为 346 项。

## 实现方案评价

以下方案设计合理，建议保留：

- `MaxWidthCenter` 将宽屏表单/文本页限宽逻辑集中为小组件；
- `coverGridDelegate` 统一五处封面网格的响应式策略；
- `platform_utils.dart` 集中管理桌面平台判断；
- Windows/Linux 走 FFI、macOS/iOS/Android 继续走 sqflite 原生插件的数据库分支正确；
- 阅读模式使用同一个 `image_index` 记录进度，避免双模式间的数据换算；
- paged → scroll 使用 `_needsScrollJump`、scroll → paged 使用 `targetIndex` 的状态衔接思路清晰；
- AlbumDetail/Reader 的 AppBar 从单纯判断 `isLoading` 改为结合 `hasValue`，正确处理“刷新但仍持有旧数据”的 Riverpod 状态；
- macOS Release/DebugProfile entitlement 中已包含网络客户端和 Keychain Sharing 配置；问题主要在签名工程配置和后处理重签步骤。

代码风格整体与项目一致。部分页面因为统一执行格式化，功能改动与大量排版变化混在同一 diff 中，提高了审查成本，但未发现因此引入的功能错误。

## 测试覆盖评价

现有测试验证了：

- GridDensity 和 ReaderMode 的配置持久化；
- AlbumDetail 刷新期间不会叠加 AppBar；
- 原滚动阅读器的起始页与断点恢复。

但本次主要新增功能缺少直接覆盖：

- `PagedReaderView` 的初始页、点击区域、滑动、长按和空列表；
- scroll ↔ paged 切换后保持当前页；
- 宽屏下 MainScreen 使用 NavigationRail，窄屏仍使用 BottomNavigationBar；
- GridDensity 对实际列数/格宽的语义；
- macOS 签名与 entitlement 保留；
- Windows 真机构建和运行时 SQLite 加载。

建议至少补充前三项 widget 测试；桌面签名和 Windows 打包可放入后续 CI 或平台冒烟检查。

## 验证结果

| 检查项 | 结果 |
| --- | --- |
| `git diff --check` | 通过 |
| `flutter analyze --fatal-infos` | 通过，0 问题 |
| `flutter test --concurrency=1` | 通过，346 项测试全部成功 |
| `bash -n scripts/release.sh` | 通过 |
| `bash -n scripts/build-flutter.sh` | 通过 |
| `bash -n scripts/package-server.sh` | 通过 |
| `bash -n scripts/sync-version.sh` | 通过 |
| `bash -n scripts/test-flutter.sh` | 通过 |
| macOS 当前 Release 产物签名检查 | 实际为 Apple Development，不是 ad-hoc |
| 模拟后处理重签 | entitlement 被全部移除 |
| Windows 真机构建 | 未验证 |

测试环境备注：直接运行 `flutter test` 时，本机代理会拦截 `flutter_tester` 回连 localhost 的 WebSocket 并返回 HTTP 503。设置 `NO_PROXY=localhost,127.0.0.1` 后完整测试通过，该失败属于本地环境问题，不是测试断言或仓库代码失败。

## 建议修复顺序

1. 清理 macOS Runner 中硬编码的开发团队和开发签名身份；
2. 重做 `CODESIGN_IDENTITY` 签名流程，确保 entitlement 与目标签名身份匹配；
3. 修正 GridDensity 迁移映射和对应测试；
4. 增加分页阅读器空列表保护，并重置 `_resumeAttempts`；
5. 补充分页模式与宽屏导航 widget 测试；
6. 删除无操作的 `sqlite3_flutter_libs` 依赖并修正文档；
7. 在 Windows 真机上完成 release 构建、启动、数据库读写和 SecureStorage 冒烟验证。
