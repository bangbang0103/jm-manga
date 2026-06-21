# AGENTS

## 项目概况

这是一个个人使用的 JM 漫画阅读 App，单仓库包含：

- `server/`：FastAPI 后端，Python 3.12+，uv 管理依赖，SQLite 持久化。
- `ui/`：Flutter 客户端，Riverpod 状态管理，dio 请求后端。
- `scripts/`：VPS 部署脚本与 systemd service。
- `docs/`：架构、部署、设计和接口探测文档。

## 工作原则

- 修改前先读相关测试和现有实现，优先沿用当前模式。
- 不要提交真实 `.env`、数据库、缓存、签名文件或本地构建产物。
- 后端服务鉴权保持 API Token 形式：`Authorization: Bearer <API_TOKEN>`。
- `/health` 是未鉴权 liveness；连接配置校验应再请求已有的受保护轻量接口。
- 生产数据目录应独立于 release 目录，当前约定为 `/opt/jm-app/data`。
- Flutter 凭据保存在 `SecureStorage`，不要退回 `SharedPreferences` 明文保存。

## 常用命令

后端：

```bash
cd server
uv run ruff check src tests
uv run ruff format --check src tests
uv run pytest tests -q
```

前端：

```bash
cd ui
flutter analyze --fatal-infos
flutter test
```

部署脚本语法检查：

```bash
bash -n scripts/deploy.sh
```

## 文档维护

- 当前事实优先写入 `README.md`、`docs/architecture.md` 和 `docs/deployment.md`。
- `docs/design.md`、`docs/ui-design.md`、`docs/prototype/` 保留为原始设计背景。
- 接口探测记录可保留为参考资料，不应当作实时事实。
