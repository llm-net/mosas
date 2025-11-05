# 🚀 Cloudflare Tunnel 快速开始

## 一条命令完成配置

由于 `cloudflared tunnel login` 需要浏览器交互，你需要按照以下步骤操作：

### 📌 方法 1: 在服务器上直接登录（推荐）

如果你的服务器有图形界面或可以访问浏览器：

```bash
cd /home/user/mosas/frontend
cloudflared tunnel login
```

然后继续运行配置脚本：

```bash
./setup-tunnel.sh
```

---

### 📌 方法 2: 本地登录后上传证书

如果服务器没有浏览器，在**本地终端**执行：

#### 2.1 本地登录
```bash
cloudflared tunnel login
```

浏览器会打开，使用以下信息登录：
- **邮箱**: me@dionren.com
- **密码**: Tubo1234!@#$
- **选择域名**: katago.org

#### 2.2 上传证书到服务器

登录成功后，上传证书文件：

```bash
# 查找证书文件位置
ls -la ~/.cloudflared/cert.pem

# 上传到服务器（替换 your-server-ip）
scp ~/.cloudflared/cert.pem user@your-server-ip:/home/user/.cloudflared/

# 或使用 SFTP/FTP 等其他方式上传
```

#### 2.3 在服务器上运行配置脚本

SSH 登录到服务器后：

```bash
cd /home/user/mosas/frontend
./setup-tunnel.sh
```

---

### 📌 方法 3: 使用 API Token（高级）

如果你有 Cloudflare API Token，可以跳过浏览器登录：

```bash
export CLOUDFLARE_API_TOKEN="your-api-token"
cd /home/user/mosas/frontend
./setup-tunnel.sh
```

---

## ✅ 验证配置

配置完成后，启动服务：

```bash
cd /home/user/mosas/frontend
./dev.sh start
```

你应该看到类似输出：

```
✓ 开发服务器已启动
  PID: 12345
  端口: 3000
  本地访问: http://localhost:3000
  日志: /tmp/mosas-frontend.log

✓ Cloudflare Tunnel 已启动
  PID: 12346
  公网访问: https://mosas.katago.org
  日志: /tmp/mosas-frontend-tunnel.log
```

现在访问 https://mosas.katago.org 即可看到你的应用！

---

## 🎯 当前需要你做的

**请执行以下其中一个方法完成登录：**

### Option A: 如果你的服务器可以打开浏览器
```bash
cd /home/user/mosas/frontend
cloudflared tunnel login
./setup-tunnel.sh
```

### Option B: 如果你在本地电脑上操作
```bash
# 1. 在本地运行
cloudflared tunnel login
# （使用 me@dionren.com / Tubo1234!@#$ 登录，选择 katago.org）

# 2. 上传证书
scp ~/.cloudflared/cert.pem user@your-server:/home/user/.cloudflared/

# 3. 在服务器运行
cd /home/user/mosas/frontend
./setup-tunnel.sh
```

**完成后告诉我，我会帮你测试隧道是否正常工作！** 🎉
