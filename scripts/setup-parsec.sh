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
    echo "   2. Check %AppData%/Parsec/ on Windows or ~/.parsec/ on Mac"
    echo "   3. Or use the API with your credentials"
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
hdiutil attach "${PARSEC_DMG}" -nobrowse -quiet || true
sleep 2

# Try to copy from mounted volume
if [ -d "/Volumes/Parsec/Parsec.app" ]; then
    cp -R "/Volumes/Parsec/Parsec.app" /Applications/
    hdiutil detach "/Volumes/Parsec" -quiet || true
else
    echo "⚠️ Could not mount DMG, trying alternative..."
    # Try to find any Parsec volume
    PARSEC_VOL=$(ls -d /Volumes/Parsec* 2>/dev/null | head -1)
    if [ -n "$PARSEC_VOL" ] && [ -d "$PARSEC_VOL/Parsec.app" ]; then
        cp -R "$PARSEC_VOL/Parsec.app" /Applications/
        hdiutil detach "$PARSEC_VOL" -quiet || true
    fi
fi

# Verify installation
if [ ! -d "/Applications/Parsec.app" ]; then
    echo "❌ Failed to install Parsec"
    exit 1
fi

echo "✅ Parsec installed"

# Create config directory
PARSEC_CONFIG_DIR="$HOME/.parsec"
mkdir -p "${PARSEC_CONFIG_DIR}"

# Create config.json (new format for Parsec 150+)
echo "⚙️ Configuring Parsec..."
cat > "${PARSEC_CONFIG_DIR}/config.json" << EOFJ
[
    "Parsec configuration",
    {
        "app_host": {"value": true},
        "app_host_name": {"value": "${PARSEC_HOST_NAME}"},
        "app_run_level": {"value": 3}
    }
]
EOFJ

# Also create legacy config.txt for compatibility
cat > "${PARSEC_CONFIG_DIR}/config.txt" << EOFT
app_host = 1
app_host_name = ${PARSEC_HOST_NAME}
app_run_level = 3
EOFT

# Create user data with session - using binary format that Parsec expects is complex
# Instead, we'll try to authenticate via the app's startup
echo "🔐 Setting up authentication..."

# Create a simple auth indicator file
echo "${PARSEC_SESSION_ID}" > "${PARSEC_CONFIG_DIR}/session_id.txt"
chmod 600 "${PARSEC_CONFIG_DIR}/session_id.txt"

# Start Parsec
echo "🚀 Starting Parsec..."
open -a Parsec &
sleep 5

# Try to authenticate via AppleScript or parsecd
echo "🔑 Attempting authentication..."

# Check if parsecd CLI exists
if [ -f "/Applications/Parsec.app/Contents/MacOS/parsecd" ]; then
    # Try to run parsecd with session
    /Applications/Parsec.app/Contents/MacOS/parsecd \
        session_id="${PARSEC_SESSION_ID}" \
        app_host=1 \
        app_host_name="${PARSEC_HOST_NAME}" &
    sleep 10
fi

# Verify Parsec is running
echo "🔍 Checking Parsec status..."
sleep 5

if pgrep -f "Parsec" > /dev/null; then
    echo ""
    echo "✅ Parsec process is running!"
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    🎮 PARSEC SETUP COMPLETE                      ║"
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
    echo "⚠️ Note: If the host does not appear, the VM may not support"
    echo "   Parsec hosting. In that case, use VNC instead."
    echo ""
else
    echo ""
    echo "⚠️ Parsec process not found."
    echo "   The macOS VM may have restrictions preventing Parsec from running."
    echo ""
    echo "💡 Alternative: Use the VNC workflow instead (mac-session.yml)"
    echo ""
fi
