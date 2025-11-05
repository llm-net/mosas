#!/bin/bash

# Cloudflare Tunnel Setup Script for MOSAS Frontend
# Domain: katago.org

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TUNNEL_NAME="mosas-frontend"
DOMAIN="katago.org"
SUBDOMAIN="mosas"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
CONFIG_DIR="$HOME/.cloudflared"
PROJECT_CONFIG_DIR="/home/user/mosas/frontend/.cloudflared"

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Cloudflare Tunnel Setup${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# Step 1: Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}✗ cloudflared not found${NC}"
    echo "Please install cloudflared first"
    exit 1
fi

echo -e "${GREEN}✓ cloudflared is installed${NC}"
cloudflared --version
echo ""

# Step 2: Login to Cloudflare
echo -e "${YELLOW}Step 1: Login to Cloudflare${NC}"
echo "Please run the following command in your terminal:"
echo ""
echo -e "${BLUE}cloudflared tunnel login${NC}"
echo ""
echo "This will:"
echo "  1. Open your browser"
echo "  2. Ask you to login to Cloudflare (me@dionren.com)"
echo "  3. Select domain: katago.org"
echo "  4. Generate cert.pem in ~/.cloudflared/"
echo ""

if [ ! -f "$CONFIG_DIR/cert.pem" ]; then
    echo -e "${YELLOW}Cert file not found. Please login first.${NC}"
    read -p "Press Enter after you have completed login..."

    if [ ! -f "$CONFIG_DIR/cert.pem" ]; then
        echo -e "${RED}✗ Still no cert.pem found at $CONFIG_DIR/cert.pem${NC}"
        echo "Please run: cloudflared tunnel login"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Found cert.pem${NC}"
echo ""

# Step 3: Create tunnel
echo -e "${YELLOW}Step 2: Creating tunnel '${TUNNEL_NAME}'${NC}"

# Check if tunnel already exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${YELLOW}Tunnel '${TUNNEL_NAME}' already exists${NC}"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
else
    echo "Creating new tunnel..."
    cloudflared tunnel create "$TUNNEL_NAME"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
fi

echo -e "${GREEN}✓ Tunnel ID: ${TUNNEL_ID}${NC}"
echo ""

# Step 4: Configure tunnel
echo -e "${YELLOW}Step 3: Configuring tunnel${NC}"

mkdir -p "$PROJECT_CONFIG_DIR"

cat > "$PROJECT_CONFIG_DIR/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: ${CONFIG_DIR}/${TUNNEL_ID}.json

ingress:
  - hostname: ${FULL_DOMAIN}
    service: http://localhost:3000
  - service: http_status:404
EOF

echo -e "${GREEN}✓ Config file created at: ${PROJECT_CONFIG_DIR}/config.yml${NC}"
echo ""

# Step 5: Create DNS record
echo -e "${YELLOW}Step 4: Creating DNS record${NC}"
echo "Creating CNAME record: ${FULL_DOMAIN} -> ${TUNNEL_ID}.cfargotunnel.com"

if cloudflared tunnel route dns "$TUNNEL_NAME" "$FULL_DOMAIN" 2>/dev/null; then
    echo -e "${GREEN}✓ DNS record created${NC}"
else
    echo -e "${YELLOW}DNS record may already exist${NC}"
fi
echo ""

# Step 6: Save tunnel info
cat > "$PROJECT_CONFIG_DIR/tunnel-info.txt" <<EOF
Tunnel Name: ${TUNNEL_NAME}
Tunnel ID: ${TUNNEL_ID}
Domain: ${FULL_DOMAIN}
Local Service: http://localhost:3000
Config File: ${PROJECT_CONFIG_DIR}/config.yml

To start the tunnel:
  cloudflared tunnel --config ${PROJECT_CONFIG_DIR}/config.yml run ${TUNNEL_NAME}

Or use the dev.sh script:
  cd /home/user/mosas/frontend
  ./dev.sh start
EOF

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "Tunnel Name: ${GREEN}${TUNNEL_NAME}${NC}"
echo -e "Tunnel ID: ${GREEN}${TUNNEL_ID}${NC}"
echo -e "Public URL: ${GREEN}https://${FULL_DOMAIN}${NC}"
echo ""
echo "To start the tunnel:"
echo -e "  ${BLUE}cd /home/user/mosas/frontend${NC}"
echo -e "  ${BLUE}./dev.sh start${NC}"
echo ""
echo "Tunnel info saved to: $PROJECT_CONFIG_DIR/tunnel-info.txt"
