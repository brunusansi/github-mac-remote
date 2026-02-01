#!/bin/bash
# setup-parsec.sh - Install and configure Parsec for remote access

set -e

PARSEC_SESSION_ID="${PARSEC_SESSION_ID:-}"
PARSEC_HOST_NAME="${PARSEC_HOST_NAME:-GitHub-Mac-${GITHUB_RUN_ID:-$(date +%s)}}"

echo "🎮 Setting up Parsec..."

# Check for session ID
if [ -z "${PARSEC_SESSION_ID}" ]; then
    echo ""
    echo "❌ ERROR: PARSEC_SESSION_ID not provided!"
    echo ""
    echo "📖 How to get your Parsec Session ID:"
    echo ""
    echo "   1. Log into Parsec on any device"
    echo "   2. Open Developer Tools (F12) in the web app or check config"
    echo "   3. Find your session_id in the authentication data"
    echo ""
    echo "   Or use the Parsec API:"
    echo "   curl -X POST https://kessel-api.parsecgaming.com/v1/auth \\\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"email\":\"your@email.com\",\"password\":\"yourpassword\"}'"
    echo ""
    echo "   Then add PARSEC_SESSION_ID to your GitHub Secrets."
    echo ""
    exit 1
fi

# Download and install Parsec
echo "📦 Downloading Parsec..."
PARSEC_DMG="/tmp/parsec.dmg"
curl -L "https://builds.parsec.app/package/parsec-macos.dmg" -o "${PARSEC_DMG}"

echo "📦 Installing Parsec..."
hdiutil attach "${PARSEC_DMG}" -nobrowse -quiet
cp -R "/Volumes/Parsec/Parsec.app" /Applications/
hdiutil detach "/Volumes/Parsec" -quiet

# Create config directory
PARSEC_CONFIG_DIR="$HOME/.parsec"
mkdir -p "${PARSEC_CONFIG_DIR}"

# Create config file with session
echo "⚙️  Configuring Parsec..."
cat > "${PARSEC_CONFIG_DIR}/config.txt" << EOF
# Parsec Configuration - GitHub Mac Remote
app_host = 1
app_host_name = ${PARSEC_HOST_NAME}
app_run_level = 3
EOF

# Create auth file with session ID
cat > "${PARSEC_CONFIG_DIR}/auth.txt" << EOF
session_id = ${PARSEC_SESSION_ID}
EOF

# Set permissions
chmod 600 "${PARSEC_CONFIG_DIR}/auth.txt"

# Start Parsec
echo "🚀 Starting Parsec..."
open -a Parsec

# Wait for Parsec to initialize
sleep 10

# Verify Parsec is running
if pgrep -x "Parsec" > /dev/null; then
    echo ""
    echo "✅ Parsec is running!"
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    🎮 PARSEC READY                               ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "   Host Name: ${PARSEC_HOST_NAME}"
    echo ""
    echo "📖 How to Connect:"
    echo ""
    echo "   1. Open Parsec on your device"
    echo "   2. Look for '${PARSEC_HOST_NAME}' in your computers list"
    echo "   3. Click to connect!"
    echo ""
    echo "   Note: Make sure you're logged into the same Parsec account."
    echo ""
else
    echo ""
    echo "⚠️  Parsec may not have started correctly."
    echo "   Check the logs for more information."
fi
