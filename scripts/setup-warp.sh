#!/bin/bash
# Cloudflare WARP Setup - Ensures unique IP via VPN
# Part of GitHub Mac Remote

set -e

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
    exit 1
fi

echo -e "${GREEN}✅ Downloaded successfully${NC}"

# Install WARP
echo -e "${BLUE}📦 Installing Cloudflare WARP...${NC}"
sudo installer -pkg "$WARP_PKG" -target / 2>/dev/null

# Wait for installation
sleep 3

# Check if warp-cli is available
if ! command -v warp-cli &> /dev/null; then
    # Try to find it
    if [ -f "/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli" ]; then
        WARP_CLI="/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli"
    else
        echo -e "${RED}❌ warp-cli not found after installation${NC}"
        exit 1
    fi
else
    WARP_CLI="warp-cli"
fi

echo -e "${GREEN}✅ Installed successfully${NC}"
echo ""

# Register WARP (free tier)
echo -e "${BLUE}📝 Registering WARP client...${NC}"

# Accept TOS and register
$WARP_CLI --accept-tos registration new 2>/dev/null || true

sleep 2

# Connect to WARP
echo -e "${BLUE}🔌 Connecting to WARP...${NC}"

$WARP_CLI connect 2>/dev/null || true

# Wait for connection
echo -e "${BLUE}⏳ Waiting for connection...${NC}"
RETRY=0
MAX_RETRY=30

while [ $RETRY -lt $MAX_RETRY ]; do
    STATUS=$($WARP_CLI status 2>/dev/null | grep -i "connected" || echo "")
    if [ -n "$STATUS" ]; then
        echo -e "${GREEN}✅ Connected to WARP!${NC}"
        break
    fi
    sleep 1
    RETRY=$((RETRY + 1))
    printf "\r   Waiting... (%d/%d)" $RETRY $MAX_RETRY
done

echo ""

if [ $RETRY -ge $MAX_RETRY ]; then
    echo -e "${YELLOW}⚠️  WARP connection timeout - continuing without VPN${NC}"
    echo "WARP_ENABLED=false" >> $GITHUB_ENV
    exit 0
fi

# Get new IP after WARP
echo -e "${BLUE}🔍 Getting new IP via WARP...${NC}"
sleep 3

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
