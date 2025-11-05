#!/bin/bash

# MOSAS Frontend Development Server Manager
# Usage: ./dev.sh {start|stop|restart|status}

PORT=3000
PID_FILE="/tmp/mosas-frontend.pid"
LOG_FILE="/tmp/mosas-frontend.log"

# Cloudflare Tunnel settings
TUNNEL_NAME="mosas-frontend"
TUNNEL_PID_FILE="/tmp/mosas-frontend-tunnel.pid"
TUNNEL_LOG_FILE="/tmp/mosas-frontend-tunnel.log"
TUNNEL_CONFIG="/home/user/mosas/frontend/.cloudflared/config.yml"
TUNNEL_INFO="/home/user/mosas/frontend/.cloudflared/tunnel-info.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    # Try lsof first
    if command -v lsof >/dev/null 2>&1; then
        lsof -i:$PORT -t >/dev/null 2>&1
        return $?
    fi

    # Try fuser as fallback
    if command -v fuser >/dev/null 2>&1; then
        fuser $PORT/tcp >/dev/null 2>&1
        return $?
    fi

    return 1
}

# Function to get PID on port
get_port_pid() {
    # Try lsof first
    if command -v lsof >/dev/null 2>&1; then
        lsof -i:$PORT -t 2>/dev/null
        return
    fi

    # Try fuser as fallback
    if command -v fuser >/dev/null 2>&1; then
        fuser $PORT/tcp 2>/dev/null | tr -d ' '
        return
    fi
}

# Function to kill process on port
kill_port() {
    echo -e "${YELLOW}检查端口 $PORT...${NC}"

    # Use fuser -k which is most reliable (kills all processes on port)
    if command -v fuser >/dev/null 2>&1; then
        if fuser $PORT/tcp >/dev/null 2>&1; then
            echo -e "${YELLOW}端口 $PORT 被占用，正在终止进程...${NC}"
            fuser -k $PORT/tcp >/dev/null 2>&1
            sleep 2
        fi
    else
        # Fallback to lsof/manual kill
        if check_port; then
            echo -e "${YELLOW}端口 $PORT 被占用，正在终止进程...${NC}"
            PID=$(get_port_pid)
            if [ -n "$PID" ]; then
                kill -9 $PID 2>/dev/null
                sleep 2
            fi
        fi
    fi

    # Final check
    if check_port || (command -v fuser >/dev/null 2>&1 && fuser $PORT/tcp >/dev/null 2>&1); then
        echo -e "${RED}无法完全清理端口 $PORT${NC}"
        return 1
    else
        if [ -n "$(get_port_pid)" ] || (command -v fuser >/dev/null 2>&1 && fuser $PORT/tcp >/dev/null 2>&1); then
            return 0
        fi
        echo -e "${GREEN}端口 $PORT 已清理${NC}"
    fi
    return 0
}

# Function to start the server
start() {
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}服务已经在运行中 (PID: $PID)${NC}"
        else
            # Stale PID file, remove it
            rm -f "$PID_FILE"
        fi
    fi

    if [ ! -f "$PID_FILE" ]; then
        # Kill any process on the port
        kill_port || return 1

        echo -e "${GREEN}启动开发服务器...${NC}"

        # Start the server in background
        npm run dev > "$LOG_FILE" 2>&1 &
        PID=$!

        # Save PID
        echo $PID > "$PID_FILE"

        # Wait a bit and check if server started successfully
        sleep 3

        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 开发服务器已启动${NC}"
            echo -e "${GREEN}  PID: $PID${NC}"
            echo -e "${GREEN}  端口: $PORT${NC}"
            echo -e "${GREEN}  本地访问: http://localhost:$PORT${NC}"
            echo -e "${GREEN}  日志: $LOG_FILE${NC}"
        else
            echo -e "${RED}✗ 服务器启动失败${NC}"
            echo -e "${RED}查看日志: $LOG_FILE${NC}"
            rm -f "$PID_FILE"
            return 1
        fi
    fi

    echo ""

    # Start tunnel if configured
    if [ -f "$TUNNEL_CONFIG" ]; then
        start_tunnel
    else
        echo -e "${YELLOW}💡 提示: 运行 ${BLUE}./setup-tunnel.sh${YELLOW} 配置公网访问${NC}"
    fi

    return 0
}

# Function to stop the server
stop() {
    local server_stopped=0
    local tunnel_stopped=0

    # Stop tunnel first
    if [ -f "$TUNNEL_PID_FILE" ] || [ -f "$TUNNEL_CONFIG" ]; then
        stop_tunnel
        tunnel_stopped=1
        echo ""
    fi

    # Stop server
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}未找到运行中的服务器${NC}"
        # Still try to kill any process on the port
        kill_port
        server_stopped=1
    else
        PID=$(cat "$PID_FILE")

        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}停止开发服务器 (PID: $PID)...${NC}"

            # Kill the entire process tree
            pkill -TERM -P $PID 2>/dev/null
            kill $PID 2>/dev/null

            # Wait for process to stop
            for i in {1..10}; do
                if ! ps -p "$PID" > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done

            # Force kill if still running
            if ps -p "$PID" > /dev/null 2>&1; then
                echo -e "${YELLOW}强制终止进程...${NC}"
                pkill -9 -P $PID 2>/dev/null
                kill -9 $PID 2>/dev/null
                sleep 3
            fi

            if ps -p "$PID" > /dev/null 2>&1; then
                echo -e "${RED}✗ 无法停止服务器${NC}"
                # Still try to clean up
                kill_port
                rm -f "$PID_FILE"
                return 1
            else
                echo -e "${GREEN}✓ 服务器已停止${NC}"
                rm -f "$PID_FILE"
                # Also kill any remaining process on port
                kill_port
                server_stopped=1
            fi
        else
            echo -e "${YELLOW}服务器未运行${NC}"
            rm -f "$PID_FILE"
            kill_port
            server_stopped=1
        fi
    fi

    return 0
}

# Function to restart the server
restart() {
    echo -e "${YELLOW}重启开发服务器...${NC}"
    stop
    sleep 3
    # Double check port is free
    kill_port
    sleep 1
    start
}

# Function to start tunnel
start_tunnel() {
    # Check if tunnel is configured
    if [ ! -f "$TUNNEL_CONFIG" ]; then
        echo -e "${YELLOW}⚠ Cloudflare Tunnel not configured${NC}"
        echo -e "  Run: ./setup-tunnel.sh to configure"
        return 1
    fi

    # Check if already running
    if [ -f "$TUNNEL_PID_FILE" ]; then
        TPID=$(cat "$TUNNEL_PID_FILE")
        if ps -p "$TPID" > /dev/null 2>&1; then
            echo -e "${YELLOW}隧道已经在运行中 (PID: $TPID)${NC}"
            return 0
        else
            rm -f "$TUNNEL_PID_FILE"
        fi
    fi

    echo -e "${BLUE}启动 Cloudflare Tunnel...${NC}"

    # Start tunnel in background
    cloudflared tunnel --config "$TUNNEL_CONFIG" run "$TUNNEL_NAME" > "$TUNNEL_LOG_FILE" 2>&1 &
    TPID=$!

    # Save PID
    echo $TPID > "$TUNNEL_PID_FILE"

    # Wait and check
    sleep 2

    if ps -p "$TPID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Cloudflare Tunnel 已启动${NC}"
        echo -e "${GREEN}  PID: $TPID${NC}"

        # Extract public URL from config
        if [ -f "$TUNNEL_INFO" ]; then
            DOMAIN=$(grep "Domain:" "$TUNNEL_INFO" | cut -d' ' -f2)
            echo -e "${GREEN}  公网访问: https://${DOMAIN}${NC}"
        fi

        echo -e "${GREEN}  日志: $TUNNEL_LOG_FILE${NC}"
        return 0
    else
        echo -e "${RED}✗ 隧道启动失败${NC}"
        echo -e "${RED}查看日志: $TUNNEL_LOG_FILE${NC}"
        rm -f "$TUNNEL_PID_FILE"
        return 1
    fi
}

# Function to stop tunnel
stop_tunnel() {
    if [ ! -f "$TUNNEL_PID_FILE" ]; then
        echo -e "${YELLOW}未找到运行中的隧道${NC}"
        return 0
    fi

    TPID=$(cat "$TUNNEL_PID_FILE")

    if ps -p "$TPID" > /dev/null 2>&1; then
        echo -e "${YELLOW}停止 Cloudflare Tunnel (PID: $TPID)...${NC}"

        # Kill tunnel process
        pkill -TERM -P $TPID 2>/dev/null
        kill $TPID 2>/dev/null

        # Wait for process to stop
        for i in {1..5}; do
            if ! ps -p "$TPID" > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done

        # Force kill if needed
        if ps -p "$TPID" > /dev/null 2>&1; then
            kill -9 $TPID 2>/dev/null
        fi

        echo -e "${GREEN}✓ 隧道已停止${NC}"
        rm -f "$TUNNEL_PID_FILE"
        return 0
    else
        echo -e "${YELLOW}隧道未运行${NC}"
        rm -f "$TUNNEL_PID_FILE"
        return 0
    fi
}

# Function to check server status
status() {
    local server_running=0
    local tunnel_running=0

    # Check server
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 开发服务器正在运行${NC}"
            echo -e "  PID: $PID"
            echo -e "  端口: $PORT"
            echo -e "  本地访问: http://localhost:$PORT"
            server_running=1
        else
            echo -e "${RED}✗ 开发服务器未运行${NC}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${RED}✗ 开发服务器未运行${NC}"
    fi

    echo ""

    # Check tunnel
    if [ -f "$TUNNEL_PID_FILE" ]; then
        TPID=$(cat "$TUNNEL_PID_FILE")
        if ps -p "$TPID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Cloudflare Tunnel 正在运行${NC}"
            echo -e "  PID: $TPID"
            if [ -f "$TUNNEL_INFO" ]; then
                DOMAIN=$(grep "Domain:" "$TUNNEL_INFO" | cut -d' ' -f2)
                echo -e "  公网访问: ${BLUE}https://${DOMAIN}${NC}"
            fi
            tunnel_running=1
        else
            echo -e "${YELLOW}✗ Cloudflare Tunnel 未运行${NC}"
            rm -f "$TUNNEL_PID_FILE"
        fi
    else
        if [ -f "$TUNNEL_CONFIG" ]; then
            echo -e "${YELLOW}✗ Cloudflare Tunnel 未运行${NC}"
            echo -e "  提示: 使用 './dev.sh start' 启动隧道"
        else
            echo -e "${YELLOW}⚠ Cloudflare Tunnel 未配置${NC}"
            echo -e "  运行: ${BLUE}./setup-tunnel.sh${NC} 进行配置"
        fi
    fi

    if [ $server_running -eq 1 ] && [ $tunnel_running -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    tunnel-start)
        start_tunnel
        ;;
    tunnel-stop)
        stop_tunnel
        ;;
    tunnel-restart)
        stop_tunnel
        sleep 1
        start_tunnel
        ;;
    setup)
        if [ -f "./setup-tunnel.sh" ]; then
            ./setup-tunnel.sh
        else
            echo -e "${RED}✗ setup-tunnel.sh not found${NC}"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|tunnel-start|tunnel-stop|tunnel-restart|setup}"
        echo ""
        echo "命令说明:"
        echo "  start          - 启动开发服务器和隧道"
        echo "  stop           - 停止开发服务器和隧道"
        echo "  restart        - 重启开发服务器和隧道"
        echo "  status         - 查看服务器和隧道状态"
        echo ""
        echo "  tunnel-start   - 仅启动 Cloudflare Tunnel"
        echo "  tunnel-stop    - 仅停止 Cloudflare Tunnel"
        echo "  tunnel-restart - 仅重启 Cloudflare Tunnel"
        echo "  setup          - 配置 Cloudflare Tunnel"
        exit 1
        ;;
esac

exit $?
