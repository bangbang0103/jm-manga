> Language: English | [中文](README.md)

# JM Manga

<img src="docs/assets/icon.png" alt="JM Manga icon" width="120">

A simple mobile manga reader app for iOS and Android. This project is built for personal learning and research purposes only.

> **Disclaimer**: This project is for personal learning and research only. It does not store or distribute any copyrighted content. All content displayed inside the app comes from third-party public interfaces, and the copyright belongs to the original authors. Please comply with your local laws and regulations. Commercial or illegal use is strictly prohibited.

## Features

- Browse recommendations, categories, rankings, and search results
- Read chapters online
- Local favorites management and manual sync
- Multi-account switching
- Reading progress persistence
- Image cache with LRU eviction and smart cleanup
- Cache inspection and cleanup UI
- HTTP / SOCKS5 proxy support
- Log level and diagnostics tools

## Installation

Pre-built packages are attached to releases when available:

- `jm-manga-apk-v<version>-android-release.apk` for Android
- `jm-manga-unsigned-ipa-v<version>-ios-release.ipa` for iOS

Each package includes a `.sha256` file for integrity verification.

### Android

1. Download the APK file.
2. Transfer it to your device.
3. Tap the file and allow installation from this source.

### iOS

The iOS package is an **unsigned IPA**. You need to sign it before installing on a non-jailbroken device.

#### Option A: Sideloadly (Recommended)

[Sideloadly](https://sideloadly.io/) is the easiest way to install unsigned IPAs without a paid Apple Developer account.

1. Download the IPA file to your computer.
2. Install and open Sideloadly.
3. Connect your iPhone or iPad to the computer.
4. Drag the IPA into Sideloadly, enter your Apple ID, and start the installation.
5. On your device, go to **Settings → General → VPN & Device Management** and trust the developer certificate.

> Depending on your Apple ID type, you may need to re-sign and reinstall the app periodically. This project does not provide an Apple Developer certificate.

#### Option B: Build and Install from Source

If you prefer to build the iOS app yourself, you need macOS with Xcode and Flutter installed.

For iOS Simulator:

```bash
git clone https://github.com/bangbang0103/jm-manga
cd app
flutter pub get
flutter build ios --simulator
flutter install
```

To install on a physical iOS device, you need a valid signing certificate and provisioning profile. Configure signing in Xcode, then build and install:

```bash
flutter build ios --release
flutter install
```

Alternatively, you can build an unsigned IPA (`flutter build ipa --no-codesign`) and sign it with Sideloadly or other tools you trust.

## Development

For local development, build instructions, and contribution guidelines, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

More documents:

- [Architecture](docs/ARCHITECTURE.md)
- [Mobile Packaging](docs/building-mobile.md)

## Standing on the Shoulders of Giants

This project could not exist without the following open-source projects and their maintainers:

- [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python) by [hect0x7](https://github.com/hect0x7)
  - A Python API for JMComic that provides access to JM web and mobile interfaces, including login, search, image decoding, categories, rankings, favorites, and API encryption/decryption. It served as an essential reference for understanding JM's interface design.

- [JMComic-qt](https://github.com/tonquer/JMComic-qt) by [tonquer](https://github.com/tonquer)
  - A cross-platform desktop JMComic client built with Qt, implementing most JM features including reading and downloading. It inspired the overall feature set and user experience direction of this mobile app.

Thank you to all the contributors of these projects for sharing their work with the community.

## License

See [LICENSE](LICENSE).
