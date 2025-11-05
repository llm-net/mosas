#!/bin/bash

# MOSAS Frontend Development Server Manager
# Usage: ./dev.sh {start|stop|restart|status}

PORT=3000
PID_FILE="/tmp/mosas-frontend.pid"
LOG_FILE="/tmp/mosas-frontend.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
            return 0
        else
            # Stale PID file, remove it
            rm -f "$PID_FILE"
        fi
    fi

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
        echo -e "${GREEN}  访问: http://localhost:$PORT${NC}"
        echo -e "${GREEN}  日志: $LOG_FILE${NC}"
        return 0
    else
        echo -e "${RED}✗ 服务器启动失败${NC}"
        echo -e "${RED}查看日志: $LOG_FILE${NC}"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Function to stop the server
stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}未找到运行中的服务器${NC}"
        # Still try to kill any process on the port
        kill_port
        return 0
    fi

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
            return 0
        fi
    else
        echo -e "${YELLOW}服务器未运行${NC}"
        rm -f "$PID_FILE"
        kill_port
        return 0
    fi
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

# Function to check server status
status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 服务器正在运行${NC}"
            echo -e "  PID: $PID"
            echo -e "  端口: $PORT"
            echo -e "  访问: http://localhost:$PORT"
            return 0
        else
            echo -e "${RED}✗ 服务器未运行 (PID文件存在但进程不存在)${NC}"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo -e "${RED}✗ 服务器未运行${NC}"
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
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动开发服务器"
        echo "  stop    - 停止开发服务器"
        echo "  restart - 重启开发服务器"
        echo "  status  - 查看服务器状态"
        exit 1
        ;;
esac

exit $?
