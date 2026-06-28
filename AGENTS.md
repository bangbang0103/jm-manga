# AGENTS

## 项目概况

这是一个个人使用的移动端漫画阅读 App，目前仅支持 iOS 与 Android。

- `app/`：Flutter 客户端，Riverpod 状态管理，dio 请求数据源接口。
- `server/`：可选自托管加速服务（FastAPI + jmcomic）。
- `scripts/`：移动端与 server 的构建/打包脚本。
- `docs/`：架构、打包、开发指南和接口探测文档。

## 工作原则

- 修改前先读相关测试和现有实现，优先沿用当前模式。
- 不要提交真实 `.env`、数据库、缓存、签名文件或本地构建产物。
- Flutter 凭据保存在 `SecureStorage`，不要退回 `SharedPreferences` 明文保存。
- 当前版本仅构建 Android APK 与 iOS 未签名 IPA，不构建其他平台包。

## 常用命令

```bash
cd app
flutter analyze --fatal-infos
flutter test
```

构建脚本语法检查：

```bash
bash -n scripts/release.sh
bash -n scripts/build-flutter.sh
bash -n scripts/package-server.sh
bash -n scripts/sync-version.sh
```

## 文档维护

- 当前事实优先写入 `README.md` 和 `docs/ARCHITECTURE.md`。
- 开发细节写入 `docs/DEVELOPMENT.md`。
- 打包说明写入 `docs/BUILDING-MOBILE.md`。
- `docs/DESIGN.md`、`docs/UI-DESIGN.md`、`docs/prototype/` 保留为原始设计背景。
- 接口探测记录可保留为参考资料，不应当作实时事实。
