# 移动端与桌面端打包指南

> 当前 Flutter 工程构建 iOS、Android、Windows 与 macOS 安装包。
> 工程已配置好 Android 包名与 macOS Bundle ID `com.jmmanga.app`，iOS 工程位于 `app/ios/`，桌面 runner 位于 `app/windows/`、`app/macos/`。

## 统一脚本

推荐使用仓库根目录的 `scripts/release.sh`：

```bash
# 移动端全量：Android APK + iOS 未签名 IPA
./scripts/release.sh mobile

# Android APK
./scripts/release.sh apk

# iOS 未签名 IPA
./scripts/release.sh ios

# 当前主机的桌面包（macOS 上构建 .app zip，Windows 上构建 runner zip）
./scripts/release.sh desktop

# 全部产物：移动端
./scripts/release.sh all
```

输出产物位于 `build/`，每个文件附带 `.sha256` 校验文件：

```text
build/jm-manga-apk-v0.1.0+1-android-release.apk
build/jm-manga-apk-v0.1.0+1-android-release.apk.sha256
build/jm-manga-unsigned-ipa-v0.1.0+1-ios-release.ipa
build/jm-manga-unsigned-ipa-v0.1.0+1-ios-release.ipa.sha256
```

可以通过环境变量覆盖产物名前缀：

```bash
APP_NAME=my-app ./scripts/release.sh apk
```

## Android

### 环境要求

- Flutter SDK
- Android SDK（包含命令行工具、platform-tools、build-tools）
- 已接受 Android SDK licenses

### 构建步骤

```bash
flutter build apk --release
```

构建产物默认位于 `app/build/app/outputs/flutter-apk/app-release.apk`。

使用仓库脚本：

```bash
./scripts/release.sh apk
```

## iOS

### 环境要求

- macOS
- Xcode 与命令行工具
- Flutter SDK

### 构建步骤

```bash
flutter build ios --release --no-codesign
```

使用仓库脚本可直接产出未签名 IPA：

```bash
./scripts/release.sh ios
```

> 该 IPA 未签名，无法直接安装到设备。分发前需使用个人/企业证书重签。

## Windows

### 环境要求

- Windows 主机 + Visual Studio（含「使用 C++ 的桌面开发」工作负载）
- Flutter SDK
- 脚本需要在 MSYS2 / Git Bash 环境执行（`release.sh windows`）

### 构建步骤

```bash
flutter build windows --release
```

使用仓库脚本可产出 zip（含 `jm_manga.exe` 与全部依赖 dll/data）：

```bash
./scripts/release.sh windows
```

## macOS

### 环境要求

- macOS + Xcode 与命令行工具
- Flutter SDK

### 构建步骤

```bash
flutter build macos --release
```

使用仓库脚本可产出 `JM Manga.app` 的 zip：

```bash
./scripts/release.sh macos
```

默认保留构建产物的 ad-hoc 签名（本机可直接运行；拷贝到其他 Mac 首次需右键 → 打开绕过 Gatekeeper）。如需用开发者证书重签：

```bash
CODESIGN_IDENTITY="Apple Development: you@example.com (TEAMID)" ./scripts/release.sh macos
```

重签不会丢失 entitlements：脚本从证书中提取 Team ID 展开 `$(AppIdentifierPrefix)`，由内向外逐个签名嵌套的 Framework/dylib，最后带 entitlements 签主 bundle（不使用会丢弃 entitlements 的裸 `codesign --deep`）。identity 也可传证书 SHA-1。

> 注意：`app/macos/Runner/Release.entitlements` 中的 `com.apple.security.network.client` 是必需配置，重建 runner 时务必保留，否则 release 包无网络能力。不要加入 `keychain-access-groups`：它需要开发团队才能构建（与 ad-hoc 默认签名冲突），macOS 端 SecureStorage 已改用文件型 keychain（`useDataProtectionKeyChain: false`），不需要该 entitlement。

## 版本同步

修改根目录 `VERSION` 后运行：

```bash
./scripts/sync-version.sh
```

脚本会把版本同步到 `app/pubspec.yaml`，格式为 `<VERSION>+<build-number>`，保持仓库版本源一致。

## 校验文件

`scripts/build-flutter.sh` 会在每个产物生成后计算 SHA256，并写入同名的 `.sha256` 文件。校验方式：

```bash
# Linux
sha256sum -c build/jm-manga-apk-v0.1.0+1-android-release.apk.sha256

# macOS
shasum -a 256 -c build/jm-manga-unsigned-ipa-v0.1.0+1-ios-release.ipa.sha256
```

## 常见问题

- iOS 构建失败提示 `flutter_secure_storage` 不支持 Swift Package Manager：目前仍可构建，未来 Flutter 升级后可能需要插件更新。
- 构建产物目录 `build/` 与 `app/build/` 已加入 `.gitignore`，请勿提交。
