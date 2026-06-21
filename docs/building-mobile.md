# 移动端打包指南

> 当前 Flutter 工程已配置好 Android 包名 `com.jmmanga.app`，iOS/macOS 工程位于 `ui/ios/` / `ui/macos/`。

## 统一构建脚本

仓库根目录提供统一构建入口，产物会复制到根目录 `build/`：

```bash
./scripts/build.sh apk
./scripts/build.sh ios
./scripts/build.sh flutter
```

产物位置：

- APK：`build/jm-manga-flutter-apk-v<version>-android-<mode>.apk`
- iOS unsigned IPA：`build/jm-manga-flutter-unsigned-ipa-v<version>-ios-<mode>.ipa`
- iOS unsigned app zip：`build/jm-manga-flutter-unsigned-app-v<version>-ios-<mode>-<host-platform>.zip`

`ios` 构建需要 macOS + Xcode；脚本始终使用 `--no-codesign`，默认产出文件名带 `unsigned` 的 IPA。脚本不会读取你的 Apple Team、证书或 Provisioning Profile，签名位置留空，交给后续手动或 CI 重签流程处理。未签名 IPA 不能直接安装到 iPhone。

## 通用前置

```bash
cd ui
flutter pub get
flutter analyze --fatal-infos
```

## Android

### 1. 检查 Android 环境

```bash
flutter doctor --android-licenses   # 接受 SDK 许可证
flutter doctor -v                    # 确认 Android toolchain 无 ×
```

> 当前环境缺少 `cmdline-tools` 时，需从 Android Studio 或[官网命令行工具](https://developer.android.com/studio#command-line-tools-only)安装并放到 `$ANDROID_HOME/cmdline-tools/latest/`。

### 2. 调试 APK

```bash
flutter build apk --debug
```

产物：`ui/build/app/outputs/flutter-apk/app-debug.apk`

### 3. Release APK / AAB

Release 包需要签名。工程已支持从 `android/key.properties` 读取正式签名，未配置时自动回退 debug 签名。

#### 方式 A：临时生成测试签名（本地测试）

```bash
cd ui/android
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias jmrelease
```

创建 `ui/android/key.properties`：

```properties
storePassword=你的密钥库密码
keyPassword=你的别名密码
keyAlias=jmrelease
storeFile=release-key.jks
```

然后打包：

```bash
cd ui
flutter build apk --release        # APK
flutter build appbundle --release  # Google Play 上架用 AAB
```

产物：

- APK：`build/app/outputs/flutter-apk/app-release.apk`
- AAB：`build/app/outputs/bundle/release/app-release.aab`

#### 方式 B：CI / 正式环境

把 `storeFile` 写成绝对路径，并把 keystore 文件放在 CI 安全存储中，不要提交到仓库。

## iOS

### 1. 检查环境

```bash
flutter doctor -v
```

需要 macOS + Xcode。构建脚本不要求登录 Apple Developer 账号。

### 2. 无签名 IPA

默认命令：

```bash
./scripts/build.sh ios
```

等价于：

```bash
IOS_EXPORT=unsigned-ipa ./scripts/build.sh ios
```

产物：

```text
build/jm-manga-flutter-unsigned-ipa-v<version>-ios-release.ipa
```

### 3. 签名位置

签名不在构建脚本中完成。后续可以把 unsigned IPA 交给 CI、Xcode Organizer、`xcodebuild -exportArchive` 或其它签名流水线处理，在那里填写 Team、证书和 Provisioning Profile。

### 4. 仅构建到 unsigned .app zip

```bash
IOS_EXPORT=unsigned-app ./scripts/build.sh ios
```

产物：

```text
build/jm-manga-flutter-unsigned-app-v<version>-ios-release-macos-arm64.zip
```

## macOS（可选）

```bash
flutter build macos --release
```

产物：`build/macos/Build/Products/Release/JM Manga.app`

## 快捷脚本

可创建一个顶层脚本：

```bash
# scripts/build_android.sh
#!/bin/bash
set -e
cd "$(dirname "$0")/../ui"
flutter build apk --release
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

```bash
# scripts/build_ios.sh
#!/bin/bash
set -e
cd "$(dirname "$0")/.."
IOS_EXPORT=unsigned-ipa ./scripts/build.sh ios
ls -lh build/*unsigned-ipa*.ipa
```

记得 `chmod +x scripts/build_*.sh`。
