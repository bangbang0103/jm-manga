# 移动端打包指南

> 当前 Flutter 工程仅构建 iOS 与 Android 安装包。
> 工程已配置好 Android 包名 `com.jmmanga.app`，iOS 工程位于 `app/ios/`。

## 统一脚本

推荐使用仓库根目录的 `scripts/release.sh`：

```bash
# 移动端全量：Android APK + iOS 未签名 IPA
./scripts/release.sh mobile

# Android APK
./scripts/release.sh apk

# iOS 未签名 IPA
./scripts/release.sh ios

# 全部产物：移动端 + server 包
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

## 版本同步

修改根目录 `VERSION` 后运行：

```bash
./scripts/sync-version.sh
```

脚本会把版本同步到 `app/pubspec.yaml`，格式为 `<VERSION>+<build-number>`。

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
