# 🔧 Cloudflare Tunnel 替代配置方案

由于服务器网络限制无法直接连接 Cloudflare API，请使用以下方法之一：

---

## 方法 1: 从 Cloudflare Dashboard 手动创建隧道（推荐）

### 步骤 1: 在 Dashboard 创建隧道

1. 登录 Cloudflare Zero Trust Dashboard:
   https://one.dash.cloudflare.com/

2. 选择 **Access** → **Tunnels**

3. 点击 **Create a tunnel**

4. 选择 **Cloudflared**

5. 输入隧道名称: `mosas-frontend`

6. 点击 **Save tunnel**

### 步骤 2: 配置隧道

在 **Public Hostnames** 标签页:

- **Subdomain**: `mosas`
- **Domain**: `katago.org`
- **Type**: `HTTP`
- **URL**: `localhost:3000`

点击 **Save**

### 步骤 3: 安装并运行隧道

Dashboard 会生成一个命令，类似：

```bash
cloudflared service install <token>
```

**在服务器上运行**:

```bash
cloudflared tunnel --no-autoupdate run --token <your-token-here>
```

将 `<your-token-here>` 替换为 Dashboard 显示的完整 token（很长的一串字符）

### 步骤 4: 保存启动脚本

将隧道启动命令保存到文件：

```bash
cat > /home/user/mosas/frontend/start-tunnel-manual.sh << 'EOF'
#!/bin/bash

TUNNEL_TOKEN="eyJ...你的完整token..."

nohup cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" > /tmp/mosas-tunnel.log 2>&1 &

echo "Tunnel started! Check log: /tmp/mosas-tunnel.log"
echo "Access: https://mosas.katago.org"
EOF

chmod +x /home/user/mosas/frontend/start-tunnel-manual.sh
```

---

## 方法 2: SSH 端口转发（临时测试）

如果你有 SSH 访问权限，可以使用本地端口转发：

```bash
# 在你的本地电脑运行
ssh -L 3000:localhost:3000 user@your-server-ip
```

然后在浏览器访问: `http://localhost:3000`

---

## 方法 3: 使用 ngrok（替代工具）

如果 Cloudflare Tunnel 不可用，可以使用 ngrok:

```bash
# 安装 ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

# 运行 (需要 ngrok 账号)
ngrok http 3000
```

---

## ✅ 推荐操作

**我建议使用方法 1**，步骤如下：

1. 访问 https://one.dash.cloudflare.com/ 登录
2. 创建隧道 `mosas-frontend`
3. 配置 Public Hostname: `mosas.katago.org` → `http://localhost:3000`
4. 复制 Dashboard 生成的 token
5. 在服务器运行:
   ```bash
   cloudflared tunnel --no-autoupdate run --token <your-token>
   ```

**完成后告诉我 token，我会帮你设置自动启动脚本！** 🚀
