# 开发指南

## 目录结构

```text
app/
  lib/                       Flutter 客户端源码
    core/                    主题等应用级基础配置
    data/                    Repository、数据映射与业务服务
    local/                   基于 SQLite 的本地收藏与阅读进度
    l10n/                    本地化 ARB 与 generated 文件
    models/                  数据模型
    network/                 网络层
      jm/                    JM 数据源 client、常量、加密、图片服务
      http_overrides*.dart   平台 HTTP 覆盖
      proxy_config*.dart     代理配置
      error_mapper.dart      错误映射
    providers/               Riverpod 状态管理
    screens/                 页面
    services/                面向远端第三方服务的封装
    utils/                   日志、存储、缓存清理、图片下载等工具
    widgets/                 通用 UI 组件
  test/                      Flutter 测试（目录与 lib/ 对应）
  assets/                    App 图标、字体等资源
  pubspec.yaml               Flutter 依赖配置

scripts/
  build.sh                   统一构建入口（apk / ios / all）
  build-flutter.sh           Flutter 构建与 sha256 校验
  sync-version.sh            将根 VERSION 同步到 pubspec.yaml
  test-flutter.sh            运行 Flutter 测试（自动设置 NO_PROXY）

docs/
  ARCHITECTURE.md            架构说明
  BUILDING-MOBILE.md         移动端构建说明
  CODEBASE.md                代码导航
  DEVELOPMENT.md             开发指南
  DESIGN.md                  设计系统
  research/                  接口探测资料
```

生成产物：

```text
build/                       构建输出，不提交
app/build/                    Flutter 构建中间产物，不提交
```

## 环境准备

```bash
cd app
flutter pub get
flutter run
```

## 版本管理

根目录 `VERSION` 是应用版本源头，格式为 `x.y.z` 或 `x.y.z-prerelease`，不要包含 Flutter 的 `+<build-number>`。修改 `VERSION` 后运行：

```bash
./scripts/sync-version.sh
```

该脚本会同步 `app/pubspec.yaml` 的版本号（保留 `+<build-number>`）。

## 代码检查

```bash
cd app
flutter analyze --fatal-infos
```

## 运行测试

```bash
./scripts/test-flutter.sh
```

> `scripts/test-flutter.sh` 会自动设置 `NO_PROXY=localhost,127.0.0.1`，避免本地代理影响 Flutter test runner 的 WebSocket 连接。如果你需要传递额外参数，可以直接传给脚本，例如 `./scripts/test-flutter.sh --name some_test`。

## 构建脚本

```bash
./scripts/build.sh apk         # Android APK
./scripts/build.sh ios         # iOS app，要求 macOS + Xcode
./scripts/build.sh all         # APK + iOS
```

构建产物命名示例：

```text
build/jm-manga-apk-v0.1.0+1-android-release.apk
build/jm-manga-unsigned-ipa-v0.1.0+1-ios-release.ipa
```

每个产物旁边会生成 `.sha256` 校验文件。

## 接口探测

`docs/research/` 目录保留了部分接口探测记录，反映当时网络环境和接口状态，仅作为实现参考，不保证长期稳定。
