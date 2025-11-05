# MOSAS Frontend

基于 Next.js、Tailwind CSS v4 和 shadcn/ui 构建的 MOSAS 前端应用。

## 技术栈

- **Next.js** 16.0.1 - React 框架
- **React** 19.2.0 - UI 库
- **TypeScript** 5.9.3 - 类型安全
- **Tailwind CSS** 4.0.0 - 样式框架
- **shadcn/ui** - UI 组件库

## 快速开始

### 安装依赖

```bash
npm install
```

### 开发服务器

使用提供的 `dev.sh` 脚本来管理开发服务器：

```bash
# 启动开发服务器
./dev.sh start

# 停止开发服务器
./dev.sh stop

# 重启开发服务器
./dev.sh restart

# 查看服务器状态
./dev.sh status
```

或者直接使用 npm 命令：

```bash
npm run dev
```

开发服务器将在 [http://localhost:3000](http://localhost:3000) 启动。

### 构建生产版本

```bash
npm run build
```

### 启动生产服务器

```bash
npm run start
```

## 项目结构

```
frontend/
├── app/                    # Next.js App Router
│   ├── globals.css        # 全局样式
│   ├── layout.tsx         # 根布局
│   └── page.tsx           # 首页
├── components/            # React 组件
│   └── ui/               # shadcn/ui 组件
│       └── button.tsx    # 按钮组件
├── lib/                   # 工具函数
│   └── utils.ts          # 通用工具
├── dev.sh                 # 开发服务器管理脚本
├── next.config.ts         # Next.js 配置
├── tailwind.config.ts     # Tailwind CSS 配置
├── tsconfig.json          # TypeScript 配置
└── package.json           # 项目依赖

```

## 开发脚本说明

`dev.sh` 脚本提供了以下功能：

- **自动端口管理**：如果 3000 端口被占用，会自动终止占用进程
- **进程管理**：使用 PID 文件追踪服务器进程
- **日志记录**：服务器日志保存在 `/tmp/mosas-frontend.log`
- **优雅关闭**：支持完整的进程树清理

## 添加 shadcn/ui 组件

使用 shadcn/ui CLI 添加新组件：

```bash
npx shadcn@latest add [component-name]
```

例如：
```bash
npx shadcn@latest add card
npx shadcn@latest add dialog
```

## 许可证

ISC
