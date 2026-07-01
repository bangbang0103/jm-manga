> 语言：[English](README.en.md) | 中文

# JM Manga

<img src="docs/assets/icon.png" alt="JM Manga icon" width="120">

一个简洁的 iOS / Android 漫画阅读应用。本项目仅供个人学习和技术研究使用。

> **免责声明**：本项目仅供个人学习和技术研究使用，不存储、不传播任何受版权保护的内容。应用内展示的所有数据均来自第三方公开接口，版权归原作者所有。请遵守当地法律法规，禁止将本项目用于任何商业或非法用途。

## 功能

- 浏览推荐、分类、排行榜和搜索结果
- 在线阅读漫画章节
- 本地收藏管理与手动同步
- 多账号切换
- 阅读进度记忆
- 图片缓存 LRU 容量限制与智能清理
- 缓存统计与一键清理界面
- HTTP / SOCKS5 代理支持
- 日志等级与诊断工具

## 安装

Release 页面会附带预编译包：

- Android：`jm-manga-apk-v<版本>-android-release.apk`
- iOS：`jm-manga-unsigned-ipa-v<版本>-ios-release.ipa`

每个包都附带同名的 `.sha256` 校验文件，可用于校验完整性。

### Android

1. 下载 APK 文件。
2. 传输到 Android 设备。
3. 点击安装并允许来自此来源的应用。

### iOS

iOS 包为**未签名 IPA**，在非越狱设备上安装前需要先签名。

#### 方式 A：Sideloadly（推荐）

[Sideloadly](https://sideloadly.io/) 是在没有付费 Apple Developer 账号的情况下安装未签名 IPA 的最简单方式。

1. 下载 IPA 文件到电脑。
2. 安装并打开 Sideloadly。
3. 用数据线将 iPhone / iPad 连接到电脑。
4. 把 IPA 拖入 Sideloadly，输入 Apple ID，开始安装。
5. 在设备上进入**设置 → 通用 → VPN 与设备管理**，信任对应的开发者证书。

> 未签名 IPA 的有效期取决于所使用的 Apple ID 类型，到期后可能需要重新签名安装。本项目不提供 Apple Developer 证书。

#### 方式 B：从源码构建并安装

如果你希望自己构建 iOS 应用，需要 macOS + Xcode + Flutter 环境。

安装到 iOS 模拟器：

```bash
git clone https://github.com/bangbang0103/jm-manga
cd app
flutter pub get
flutter build ios --simulator
flutter install
```

如果要在真机上安装，需要有效的签名证书和描述文件。在 Xcode 中配置好签名后执行：

```bash
flutter build ios --release
flutter install
```

也可以构建未签名 IPA（`flutter build ipa --no-codesign`），再通过 Sideloadly 或其他你信任的工具签名安装。

## 开发

本地开发环境、构建说明和开发规范见 [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)。

更多文档：

- [架构说明](docs/ARCHITECTURE.md)
- [移动端打包](docs/building-mobile.md)

## 站在巨人的肩膀上

本项目离不开以下开源项目及其维护者的贡献：

- [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python)（作者：[hect0x7](https://github.com/hect0x7)）
- 一个针对 JMComic 的 Python API，支持访问 JM 的网页版及移动端接口，涵盖登录、搜索、图片解码、分类、排行榜、收藏以及 API 加解密等功能。它为理解 JM 的接口设计提供了重要参考。

- [JMComic-qt](https://github.com/tonquer/JMComic-qt)（作者：[tonquer](https://github.com/tonquer)）
- 一个基于 Qt 开发的跨平台 JMComic 桌面客户端，实现了包括阅读和下载在内的大部分 JM 功能。它为本移动端应用的功能规划和用户体验设计提供了灵感。

感谢这些项目的贡献者与社区分享他们的成果。

## 许可证

详见 [LICENSE](LICENSE)。
