# crisp-reverse-proxy

基于 Nginx 和 Docker 的 Crisp 反向代理解决方案 (Docker 全自动版)。

本项目特点：**零维护、全自动 SSL 证书申请与续期、配置简单**。

## 🚀 快速开始

### 1. 准备工作
*   一台拥有公网 IP 的服务器（推荐 Linux）。
*   已安装 Docker 和 Docker Compose。
*   将域名解析到该服务器。

### 2. 下载与部署
将本项目所有文件上传到服务器，然后按以下步骤操作。

#### 第一步：配置 .env
复制或修改 `.env` 文件，填入您的真实域名和邮箱：

```ini
# 主客户端域名 (例如: kefu.yourdomain.com)
CLIENT_DOMAIN=client.yourdomain.com

# 图片资源域名 (例如: img.yourdomain.com)
IMAGE_DOMAIN=image.yourdomain.com

# WebSocket 域名 (例如: ws.yourdomain.com)
RELAY_DOMAIN=relay.yourdomain.com
CLIENT_RELAY_DOMAIN=client.relay.yourdomain.com

# 其他功能域名 (保持二级域名格式即可，例如: game.yourdomain.com)
GAME_DOMAIN=game.yourdomain.com
GO_DOMAIN=go.yourdomain.com
MEDIA_DOMAIN=media.yourdomain.com

# Let's Encrypt 注册邮箱 (用于接收证书过期通知，必填)
CERT_EMAIL=admin@yourdomain.com
```

#### 第二步：启动服务
在项目根目录下运行：

```bash
docker-compose up -d
```

### 3. 使用方法
启动后，请耐心等待 1-2 分钟。
*   **首次启动**：Nginx 会先使用临时证书启动，后台 Certbot 会自动申请真实证书并重载 Nginx。
*   **验证**：访问 `https://client.yourdomain.com/l.js`，如果能正常加载且浏览器无安全警告，说明部署成功。

#### 更新 Crisp 集成代码
在您的网站 HTML 中，更新 Crisp 的初始化代码，指定 `go` 参数为您的代理域名：

```javascript
$crisp.push(["set", "session:domain", "client.yourdomain.com"]);
// 或者在 script 标签中添加 data-domain 属性以防万一，
// 但最重要的是确保加载的 script src 指向您的 client.yourdomain.com
```

---

## 🛠️ 目录结构说明

*   **`.env`**: 核心配置文件，管理域名和邮箱。
*   **`docker-compose.yml`**: 容器编排文件，定义了 Nginx 和 Certbot 服务。
*   **`templates/`**: Nginx 配置模板。启动时会自动读取 `.env` 中的变量并生成最终配置。
*   **`scripts/`**: 容器启动脚本。
    *   `nginx-entrypoint.sh`: 处理配置生成、临时证书 fallback 和热重载。
    *   `certbot-entrypoint.sh`: 处理证书申请和自动续期循环。
*   **`certs/live`**: 存放 SSL 证书的目录（自动映射到宿主机，方便备份）。

## ⚙️ 自动续期原理
本方案内置了守护进程：
1.  **Certbot** 容器会每 12 小时自动检查一次证书状态。
2.  如果证书即将过期（<30天），它会自动续期。
3.  续期成功后，它会发送信号给 Nginx 容器，触发 Nginx 无缝重载配置。
4.  全程无需人工干预。

## ⚠️ 常见问题
*   **刚启动时浏览器提示证书不安全？**
    *   这是正常的。首次启动时使用的是临时自签名证书。请等待几分钟，直到 Certbot 申请到 Let's Encrypt 的真证书。
*   **证书申请失败？**
    *   请检查 `.env` 中的 `CERT_EMAIL` 是否填写。
    *   请检查所有域名是否都正确解析到了本机 IP。
    *   请检查服务器的 80 和 443 端口是否开放。
