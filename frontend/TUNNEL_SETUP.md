# Cloudflare Tunnel 配置指南

本指南将帮助你配置 Cloudflare Tunnel，实现公网访问 MOSAS 前端应用。

## 📋 前提条件

- ✅ Cloudflare 账号: me@dionren.com
- ✅ 域名: katago.org
- ✅ cloudflared 已安装

## 🚀 配置步骤

### 步骤 1: 登录 Cloudflare

在**你的本地终端**（不是服务器）运行以下命令：

```bash
cloudflared tunnel login
```

这将：
1. 打开浏览器
2. 要求登录 Cloudflare 账号 (me@dionren.com)
3. 选择域名 `katago.org` 进行授权
4. 在 `~/.cloudflared/` 目录生成 `cert.pem` 文件

### 步骤 2: 上传 cert.pem 到服务器

登录成功后，将生成的证书文件上传到服务器：

```bash
# 在本地终端执行
scp ~/.cloudflared/cert.pem user@your-server:/home/user/.cloudflared/
```

或者手动复制 `~/.cloudflared/cert.pem` 文件内容，然后在服务器上创建该文件。

### 步骤 3: 运行配置脚本

在服务器上运行配置脚本：

```bash
cd /home/user/mosas/frontend
./setup-tunnel.sh
```

脚本将自动：
- ✅ 创建名为 `mosas-frontend` 的隧道
- ✅ 生成隧道配置文件
- ✅ 创建 DNS 记录 `mosas.katago.org`
- ✅ 配置将流量转发到 localhost:3000

### 步骤 4: 启动服务

配置完成后，启动开发服务器和隧道：

```bash
./dev.sh start
```

你的应用现在可以通过以下地址访问：
- **本地访问**: http://localhost:3000
- **公网访问**: https://mosas.katago.org

## 🎮 使用命令

### 基本命令

```bash
# 启动服务器和隧道
./dev.sh start

# 停止服务器和隧道
./dev.sh stop

# 重启服务器和隧道
./dev.sh restart

# 查看状态
./dev.sh status
```

### 隧道专用命令

```bash
# 仅启动隧道
./dev.sh tunnel-start

# 仅停止隧道
./dev.sh tunnel-stop

# 仅重启隧道
./dev.sh tunnel-restart

# 重新配置隧道
./dev.sh setup
```

## 📝 配置文件说明

配置完成后会生成以下文件：

```
~/.cloudflared/
├── cert.pem                    # Cloudflare 认证证书
└── <tunnel-id>.json           # 隧道凭证文件

/home/user/mosas/frontend/.cloudflared/
├── config.yml                 # 隧道配置文件
└── tunnel-info.txt           # 隧道信息（Tunnel ID、域名等）
```

### config.yml 配置示例

```yaml
tunnel: <your-tunnel-id>
credentials-file: /home/user/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: mosas.katago.org
    service: http://localhost:3000
  - service: http_status:404
```

## 🔍 故障排除

### 隧道无法启动

1. **检查证书文件**
   ```bash
   ls -la ~/.cloudflared/cert.pem
   ```

2. **查看隧道日志**
   ```bash
   tail -f /tmp/mosas-frontend-tunnel.log
   ```

3. **验证隧道配置**
   ```bash
   cloudflared tunnel info mosas-frontend
   ```

### DNS 解析问题

检查 DNS 记录是否正确：
```bash
nslookup mosas.katago.org
# 或
dig mosas.katago.org
```

应该看到一个 CNAME 记录指向 `<tunnel-id>.cfargotunnel.com`

### 手动创建 DNS 记录

如果自动创建失败，可以手动在 Cloudflare Dashboard 创建：

1. 登录 Cloudflare Dashboard
2. 选择域名 `katago.org`
3. 进入 DNS 设置
4. 添加 CNAME 记录：
   - **Name**: mosas
   - **Target**: `<tunnel-id>.cfargotunnel.com`
   - **Proxy status**: Proxied (橙色云朵)

## 🔐 安全说明

- `cert.pem` 文件包含敏感信息，请妥善保管
- 不要将 `cert.pem` 和隧道凭证文件提交到 Git 仓库
- 已在 `.gitignore` 中排除 `.cloudflared/` 目录

## 🌐 Cloudflare Dashboard

访问 Cloudflare Zero Trust Dashboard 管理隧道：
https://one.dash.cloudflare.com/

在这里你可以：
- 查看所有隧道
- 监控流量
- 修改配置
- 删除隧道

## 📞 需要帮助？

如果遇到问题，可以：

1. 查看官方文档: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
2. 检查日志文件:
   - 服务器日志: `/tmp/mosas-frontend.log`
   - 隧道日志: `/tmp/mosas-frontend-tunnel.log`
3. 验证隧道列表: `cloudflared tunnel list`
