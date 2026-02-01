#!/bin/bash
# Cloudflare WARP Setup - Ensures unique IP via VPN
# Part of GitHub Mac Remote

# Don't exit on error - we handle errors manually
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              🔒 CLOUDFLARE WARP SETUP                            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get original IP before WARP
echo -e "${BLUE}🔍 Getting original IP...${NC}"
ORIGINAL_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "unknown")
echo -e "   Original IP: ${ORIGINAL_IP}"
echo ""

# Download and install Cloudflare WARP
echo -e "${BLUE}📥 Downloading Cloudflare WARP...${NC}"

WARP_PKG="/tmp/Cloudflare_WARP.pkg"

# Download the latest WARP client for macOS
curl -L -o "$WARP_PKG" "https://1111-releases.cloudflareclient.com/mac/Cloudflare_WARP.pkg" 2>/dev/null

if [ ! -f "$WARP_PKG" ]; then
    echo -e "${RED}❌ Failed to download Cloudflare WARP${NC}"
    echo "WARP_ENABLED=false" >> $GITHUB_ENV
    exit 0
fi

echo -e "${GREEN}✅ Downloaded successfully${NC}"

# Install WARP
echo -e "${BLUE}📦 Installing Cloudflare WARP...${NC}"
sudo installer -pkg "$WARP_PKG" -target /

echo -e "${GREEN}✅ Installed successfully${NC}"
echo ""

# Find warp-cli
WARP_CLI=""
if [ -f "/usr/local/bin/warp-cli" ]; then
    WARP_CLI="/usr/local/bin/warp-cli"
elif [ -f "/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli" ]; then
    WARP_CLI="/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli"
elif command -v warp-cli &> /dev/null; then
    WARP_CLI="warp-cli"
fi

if [ -z "$WARP_CLI" ]; then
    echo -e "${RED}❌ warp-cli not found after installation${NC}"
    echo "WARP_ENABLED=false" >> $GITHUB_ENV
    exit 0
fi

echo -e "${BLUE}📍 Found warp-cli at: ${WARP_CLI}${NC}"

# Start the WARP daemon service
echo -e "${BLUE}🚀 Starting WARP daemon...${NC}"

# Load the LaunchDaemon
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.1dot1dot1dot1.macos.warp.daemon.plist 2>/dev/null || true

# Also try starting it directly
sudo launchctl start com.cloudflare.1dot1dot1dot1.macos.warp.daemon 2>/dev/null || true

# Wait for daemon to be ready
echo -e "${BLUE}⏳ Waiting for daemon to start...${NC}"
sleep 5

# Check daemon status
for i in {1..10}; do
    DAEMON_STATUS=$($WARP_CLI status 2>&1)
    if echo "$DAEMON_STATUS" | grep -qi "unable to connect\|error\|not running"; then
        echo -e "   Daemon not ready, retrying... ($i/10)"
        sleep 2
    else
        echo -e "${GREEN}✅ Daemon is running${NC}"
        break
    fi
done

# Show current status
echo -e "${BLUE}📊 Current WARP status:${NC}"
$WARP_CLI status 2>&1 || true
echo ""

# Accept TOS and register
echo -e "${BLUE}📝 Registering WARP client (accepting TOS)...${NC}"

# Method 1: Try with --accept-tos flag
$WARP_CLI --accept-tos registration new 2>&1 || true

sleep 2

# Check registration status
REG_STATUS=$($WARP_CLI registration show 2>&1 || echo "")
echo -e "   Registration status: ${REG_STATUS}"

# If not registered, try alternative method
if echo "$REG_STATUS" | grep -qi "missing\|error\|not registered"; then
    echo -e "${YELLOW}   Trying alternative registration...${NC}"
    # Try setting mode first
    $WARP_CLI mode warp 2>&1 || true
    sleep 1
    $WARP_CLI registration new 2>&1 || true
    sleep 2
fi

# Set WARP mode (full tunnel)
echo -e "${BLUE}⚙️  Setting WARP mode...${NC}"
$WARP_CLI mode warp 2>&1 || true

# Connect to WARP
echo -e "${BLUE}🔌 Connecting to WARP...${NC}"
$WARP_CLI connect 2>&1 || true

# Wait for connection with better status checking
echo -e "${BLUE}⏳ Waiting for connection...${NC}"
RETRY=0
MAX_RETRY=30
CONNECTED=false

while [ $RETRY -lt $MAX_RETRY ]; do
    STATUS=$($WARP_CLI status 2>&1)
    
    if echo "$STATUS" | grep -qi "connected"; then
        echo ""
        echo -e "${GREEN}✅ Connected to WARP!${NC}"
        CONNECTED=true
        break
    elif echo "$STATUS" | grep -qi "connecting"; then
        printf "\r   Connecting... (%d/%d)" $RETRY $MAX_RETRY
    elif echo "$STATUS" | grep -qi "disconnected\|disabled"; then
        # Try to connect again
        $WARP_CLI connect 2>&1 >/dev/null || true
        printf "\r   Reconnecting... (%d/%d)" $RETRY $MAX_RETRY
    else
        printf "\r   Waiting... (%d/%d) - Status: %s" $RETRY $MAX_RETRY "$(echo $STATUS | head -c 30)"
    fi
    
    sleep 1
    RETRY=$((RETRY + 1))
done

echo ""

# Final status check
echo -e "${BLUE}📊 Final WARP status:${NC}"
$WARP_CLI status 2>&1 || true
echo ""

if [ "$CONNECTED" = false ]; then
    echo -e "${YELLOW}⚠️  WARP connection could not be established${NC}"
    echo -e "${YELLOW}   This may be due to network restrictions on GitHub runners${NC}"
    echo "WARP_ENABLED=false" >> $GITHUB_ENV
    
    # Cleanup
    rm -f "$WARP_PKG" 2>/dev/null || true
    exit 0
fi

# Wait a bit for network to stabilize
sleep 3

# Get new IP after WARP
echo -e "${BLUE}🔍 Getting new IP via WARP...${NC}"
NEW_IP=$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null || echo "unknown")

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🔄 IP CHANGE SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Original IP:  ${YELLOW}${ORIGINAL_IP}${NC}"
echo -e "  New IP:       ${GREEN}${NEW_IP}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$ORIGINAL_IP" = "$NEW_IP" ]; then
    echo -e "${YELLOW}⚠️  IP did not change (WARP may not be routing traffic)${NC}"
    echo "WARP_ENABLED=false" >> $GITHUB_ENV
else
    echo -e "${GREEN}✅ IP successfully changed via Cloudflare WARP!${NC}"
    echo "WARP_ENABLED=true" >> $GITHUB_ENV
    echo "WARP_IP=${NEW_IP}" >> $GITHUB_ENV
    echo "ORIGINAL_IP=${ORIGINAL_IP}" >> $GITHUB_ENV
fi

# Get new IP details
IP_DETAILS=$(curl -s --max-time 5 "https://ipinfo.io/${NEW_IP}/json" 2>/dev/null || echo "{}")
IP_CITY=$(echo "$IP_DETAILS" | grep -o '"city": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")
IP_COUNTRY=$(echo "$IP_DETAILS" | grep -o '"country": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")
IP_ORG=$(echo "$IP_DETAILS" | grep -o '"org": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")

echo ""
echo -e "  📍 New Location: ${IP_CITY}, ${IP_COUNTRY}"
echo -e "  🏢 New Provider: ${IP_ORG}"
echo ""

# Update environment with new IP info
echo "CURRENT_IP=${NEW_IP}" >> $GITHUB_ENV
echo "IP_CITY=${IP_CITY}" >> $GITHUB_ENV
echo "IP_COUNTRY=${IP_COUNTRY}" >> $GITHUB_ENV

echo -e "${GREEN}✅ WARP setup complete${NC}"
echo ""

# Cleanup
rm -f "$WARP_PKG" 2>/dev/null || true
