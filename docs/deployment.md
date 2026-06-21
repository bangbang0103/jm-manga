# JM Manga Server 部署指南

> 针对局域网和公网部署的说明，包含网络模式、TLS、数据目录、源码包和 systemd 示例。

## 1. 前置准备

- Python 3.12+
- [uv](https://docs.astral.sh/uv/)
- Flutter SDK（仅在需要构建 Web / APK / iOS 产物时需要）
- 公网部署建议准备域名和 HTTPS 反向代理

默认运行数据放在 `$HOME/.jm-manga`：

```bash
DB_PATH=$HOME/.jm-manga/app.db
CACHE_DIR=$HOME/.jm-manga/cache
```

如需放到其它磁盘或目录，设置 `DB_PATH` 和 `CACHE_DIR` 即可覆盖。不要把数据库和缓存放进 release、源码或 `build/` 目录。

## 2. 关键环境变量

```bash
# 网络模式：lan | public | auto
NETWORK_MODE=public

# 公网模式必填
API_TOKEN=your_strong_random_token
IMAGE_SIGN_SECRET=another_strong_random_secret

# JM 密码落盘加密密钥
JM_PASSWORD_ENCRYPTION_KEY=your_encryption_key_for_password

# 服务
ENV=production
LOG_LEVEL=INFO
HOST=127.0.0.1
PORT=8000

# 存储，可省略以使用默认 $HOME/.jm-manga
DB_PATH=$HOME/.jm-manga/app.db
CACHE_DIR=$HOME/.jm-manga/cache
```

网络模式：

- `lan`：允许 `API_TOKEN` 为空，可启用 mDNS，适合可信局域网。
- `public`：要求 `API_TOKEN` 和 `IMAGE_SIGN_SECRET` 非空，并关闭 mDNS。
- `auto`：根据 `HOST` 推断。`0.0.0.0` 或公网地址按 public，其它本机或私网地址按 lan。

公网部署务必使用 `NETWORK_MODE=public`，并设置强随机 token。

## 3. HTTPS

JM Manga Server 自身不终止 TLS。公网部署时建议让后端只监听 `127.0.0.1:8000`，前面放 Caddy 或 Nginx。

Caddy：

```Caddyfile
jm.example.com {
    reverse_proxy 127.0.0.1:8000
}
```

Nginx：

```nginx
server {
    listen 443 ssl http2;
    server_name jm.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

局域网 PWA 安装同样建议 HTTPS。可以使用域名 + DNS-01 证书，或在受控设备上安装私有 CA / mkcert 根证书。

## 4. 源码运行

```bash
cd server
uv sync
uv run jm-manga-server init-env --path $HOME/.jm-manga/.env
uv run jm-manga-server
```

如果使用生成的 `.env`，其中的 `$HOME` 会在服务读取配置时展开。

## 5. 构建产物

后端构建产物是 Python 源码包，不再构建 standalone 二进制。

构建产物版本来自根目录 `VERSION`。发布前如有改版本，先运行：

```bash
./scripts/sync-version.sh
```

```bash
./scripts/build.sh server
./scripts/build.sh server-web
./scripts/build.sh web
./scripts/build.sh apk
./scripts/build.sh ios
```

最终产物都直接放在 `build/` 下：

```text
build/jm-manga-server-source-v<version>-<platform>.tar.gz
build/jm-manga-server-source-web-v<version>-<platform>.tar.gz
build/jm-manga-flutter-web-v<version>-web-<mode>.tar.gz
build/jm-manga-flutter-apk-v<version>-android-<mode>.apk
build/jm-manga-flutter-unsigned-*.zip|*.ipa
```

源码包运行示例：

```bash
tar -xzf build/jm-manga-server-source-v<version>-python.tar.gz
cd jm-manga-server-source-v<version>/server
uv sync
uv run jm-manga-server init-env --path $HOME/.jm-manga/.env
uv run jm-manga-server
```

`server-web` 会先构建 Flutter Web，并把 Web 产物放进源码包里的 `server/web/`。单独运行 `./scripts/build.sh web` 时，Web tar 会写入 `build/`，并复制一份到本地 `server/web/` 供 FastAPI 服务。

iOS 构建不使用本机签名，默认产出 `unsigned` IPA。签名、Team 和 Provisioning Profile 留给后续手动或 CI 重签流程。

## 6. JMComic 依赖更新

服务端依赖 `jmcomic`。`server/pyproject.toml` 使用 `jmcomic>=2.7.0`，但 `server/uv.lock` 会固定实际解析到的版本，保证部署可复现。

如果 JMComic 发布新版，可以运行：

```bash
./scripts/update-jmcomic.sh
cd server
uv run pytest tests -q
```

这会尝试把 `jmcomic` 升级到当前可解析的最新版，并更新 `server/uv.lock`。如果测试通过，再提交新的 lockfile。这样比每次运行时无锁拉最新版更干净，也更容易回滚。

## 7. systemd 示例

创建专用用户时，建议给它一个明确的 home，例如 `/var/lib/jm-manga`，这样默认数据目录会落在 `/var/lib/jm-manga/.jm-manga`：

```bash
sudo useradd -r -m -d /var/lib/jm-manga -s /usr/sbin/nologin jm-manga
sudo -u jm-manga mkdir -p /var/lib/jm-manga/.jm-manga
```

示例 service：

```ini
[Unit]
Description=JM Manga Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=jm-manga
WorkingDirectory=/path/to/jm-manga/server
EnvironmentFile=/var/lib/jm-manga/.jm-manga/.env
ExecStart=/usr/bin/env uv run jm-manga-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

首次生成环境文件：

```bash
cd /path/to/jm-manga/server
sudo -u jm-manga uv run jm-manga-server init-env --path /var/lib/jm-manga/.jm-manga/.env
sudo chmod 600 /var/lib/jm-manga/.jm-manga/.env
```

## 8. 安全清单

- [ ] 公网部署已设置 `NETWORK_MODE=public`。
- [ ] `API_TOKEN`、`IMAGE_SIGN_SECRET`、`JM_PASSWORD_ENCRYPTION_KEY` 都是强随机值。
- [ ] 已启用 HTTPS，后端只监听 `127.0.0.1`。
- [ ] `.env` 权限为 `0600`，未提交到仓库。
- [ ] `DB_PATH` 和 `CACHE_DIR` 不在源码、release 或 `build/` 目录内。
- [ ] 运行用户拥有 `$HOME/.jm-manga` 或自定义数据目录的读写权限。
