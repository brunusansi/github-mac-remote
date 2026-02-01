#!/bin/bash
# IP Manager - Detects, tracks, and ensures unique IPs
# Part of GitHub Mac Remote

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
IP_HISTORY_FILE="${GITHUB_WORKSPACE}/.ip-history.json"
IP_CACHE_KEY="ip-history-${GITHUB_REPOSITORY_OWNER}"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    🌐 IP MANAGER                                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to get public IP
get_public_ip() {
    local ip=""
    
    # Try multiple services for reliability
    ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://icanhazip.com 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://ipecho.net/plain 2>/dev/null)
    
    echo "$ip"
}

# Function to get IP details
get_ip_details() {
    local ip="$1"
    local details=""
    
    details=$(curl -s --max-time 5 "https://ipinfo.io/${ip}/json" 2>/dev/null) || details="{}"
    
    echo "$details"
}

# Get current public IP
echo -e "${BLUE}🔍 Detecting public IP...${NC}"
CURRENT_IP=$(get_public_ip)

if [ -z "$CURRENT_IP" ]; then
    echo -e "${RED}❌ Failed to detect public IP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Current IP: ${CURRENT_IP}${NC}"

# Get IP details (location, ISP, etc.)
echo -e "${BLUE}📍 Getting IP details...${NC}"
IP_DETAILS=$(get_ip_details "$CURRENT_IP")

IP_CITY=$(echo "$IP_DETAILS" | grep -o '"city": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")
IP_REGION=$(echo "$IP_DETAILS" | grep -o '"region": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")
IP_COUNTRY=$(echo "$IP_DETAILS" | grep -o '"country": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")
IP_ORG=$(echo "$IP_DETAILS" | grep -o '"org": *"[^"]*"' | cut -d'"' -f4 || echo "Unknown")

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  📍 IP Information${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  IP Address:  ${GREEN}${CURRENT_IP}${NC}"
echo -e "  Location:    ${IP_CITY}, ${IP_REGION}, ${IP_COUNTRY}"
echo -e "  Provider:    ${IP_ORG}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Export IP info as environment variables
echo "CURRENT_IP=${CURRENT_IP}" >> $GITHUB_ENV
echo "IP_CITY=${IP_CITY}" >> $GITHUB_ENV
echo "IP_COUNTRY=${IP_COUNTRY}" >> $GITHUB_ENV
echo "IP_ORG=${IP_ORG}" >> $GITHUB_ENV

# Check for IP history (loaded from cache in workflow)
ACTOR="${GITHUB_ACTOR:-unknown}"
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

if [ -f "$IP_HISTORY_FILE" ]; then
    echo -e "${BLUE}📋 Checking IP history...${NC}"
    
    # Check if this IP was used before by anyone
    if grep -q "\"ip\": *\"${CURRENT_IP}\"" "$IP_HISTORY_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  WARNING: This IP has been used before!${NC}"
        
        # Find who used it
        PREVIOUS_USER=$(grep -B5 "\"ip\": *\"${CURRENT_IP}\"" "$IP_HISTORY_FILE" | grep -o '"user": *"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
        PREVIOUS_DATE=$(grep -B5 "\"ip\": *\"${CURRENT_IP}\"" "$IP_HISTORY_FILE" | grep -o '"timestamp": *"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
        
        echo -e "${YELLOW}   Previously used by: ${PREVIOUS_USER}${NC}"
        echo -e "${YELLOW}   Date: ${PREVIOUS_DATE}${NC}"
        echo ""
        
        echo "IP_IS_DUPLICATE=true" >> $GITHUB_ENV
        echo "IP_PREVIOUS_USER=${PREVIOUS_USER}" >> $GITHUB_ENV
    else
        echo -e "${GREEN}✅ This is a fresh IP (not in history)${NC}"
        echo "IP_IS_DUPLICATE=false" >> $GITHUB_ENV
    fi
else
    echo -e "${BLUE}📝 No IP history found (first run)${NC}"
    echo "IP_IS_DUPLICATE=false" >> $GITHUB_ENV
    # Create empty history file
    echo '{"history": []}' > "$IP_HISTORY_FILE"
fi

# Add current IP to history
echo -e "${BLUE}💾 Recording IP in history...${NC}"

# Create new entry
NEW_ENTRY="{\"ip\": \"${CURRENT_IP}\", \"user\": \"${ACTOR}\", \"timestamp\": \"${TIMESTAMP}\", \"city\": \"${IP_CITY}\", \"country\": \"${IP_COUNTRY}\", \"org\": \"${IP_ORG}\", \"run_id\": \"${GITHUB_RUN_ID}\"}"

# Read existing history and append
if [ -f "$IP_HISTORY_FILE" ]; then
    # Simple append to JSON array (basic JSON manipulation without jq)
    # Read file, remove last }], add new entry, close array
    EXISTING=$(cat "$IP_HISTORY_FILE")
    
    if echo "$EXISTING" | grep -q '"history": \[\]'; then
        # Empty history
        echo "{\"history\": [${NEW_ENTRY}]}" > "$IP_HISTORY_FILE"
    else
        # Has entries - append
        # Remove trailing }] and add new entry
        UPDATED=$(echo "$EXISTING" | sed 's/\]}$//' | sed 's/$/,/')
        echo "${UPDATED}${NEW_ENTRY}]}" > "$IP_HISTORY_FILE"
    fi
else
    echo "{\"history\": [${NEW_ENTRY}]}" > "$IP_HISTORY_FILE"
fi

echo -e "${GREEN}✅ IP recorded in history${NC}"
echo ""

# Summary
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    📊 IP SUMMARY                                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  🌐 Public IP:     ${GREEN}${CURRENT_IP}${NC}"
echo -e "  📍 Location:      ${IP_CITY}, ${IP_COUNTRY}"
echo -e "  🏢 Provider:      ${IP_ORG}"
echo -e "  👤 User:          ${ACTOR}"
echo -e "  🕐 Timestamp:     ${TIMESTAMP}"
echo ""
