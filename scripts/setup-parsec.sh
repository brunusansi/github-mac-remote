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
PARSEC_PKG="/tmp/parsec.pkg"

# Note: Parsec now uses .pkg format instead of .dmg
curl -L "https://builds.parsec.app/package/parsec-macos.pkg" -o "${PARSEC_PKG}" --progress-bar

# Verify download
FILE_SIZE=$(stat -f%z "${PARSEC_PKG}" 2>/dev/null || stat --printf="%s" "${PARSEC_PKG}" 2>/dev/null || echo "0")
echo "   Downloaded: ${FILE_SIZE} bytes"

if [ "${FILE_SIZE}" -lt 1000000 ]; then
    echo "❌ Download failed - file too small (${FILE_SIZE} bytes)"
    echo "   Expected ~3.4MB for Parsec installer"
    echo "   Content of downloaded file:"
    head -c 500 "${PARSEC_PKG}" || true
    exit 1
fi

echo "✅ Download complete (${FILE_SIZE} bytes)"

# Install using installer command (for .pkg files)
echo "📦 Installing Parsec..."
sudo installer -pkg "${PARSEC_PKG}" -target / || {
    echo "❌ Failed to install Parsec via installer command"
    exit 1
}

# Verify installation
echo "🔍 Checking installation..."
sleep 2

if [ -d "/Applications/Parsec.app" ]; then
    echo "✅ Parsec installed to /Applications/Parsec.app"
    ls -la /Applications/Parsec.app/Contents/MacOS/ 2>/dev/null || true
else
    echo "⚠️ Parsec.app not in /Applications, searching..."
    # Check common locations
    find /Applications -name "Parsec*" -type d 2>/dev/null || true
    find /usr/local -name "parsec*" 2>/dev/null || true
    
    echo "❌ Failed to find Parsec installation"
    exit 1
fi

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

# Get the actual bundle name from Info.plist
BUNDLE_NAME=""
if [ -f "/Applications/Parsec.app/Contents/Info.plist" ]; then
    BUNDLE_NAME=$(defaults read /Applications/Parsec.app/Contents/Info.plist CFBundleName 2>/dev/null || echo "")
    echo "   Bundle name: ${BUNDLE_NAME:-Unknown}"
fi

# Try multiple methods to start Parsec
PARSEC_STARTED=false

# Method 1: Open using full path
echo "   Trying: open /Applications/Parsec.app"
if open /Applications/Parsec.app 2>/dev/null; then
    echo "   ✓ open command succeeded"
    sleep 3
    if pgrep -f "parsecd" > /dev/null; then
        PARSEC_STARTED=true
        echo "   ✓ Parsec process detected"
    fi
fi

# Method 2: Run parsecd directly if Method 1 didn't work
if [ "$PARSEC_STARTED" = false ] && [ -f "/Applications/Parsec.app/Contents/MacOS/parsecd" ]; then
    echo "   Trying: Run parsecd directly"
    nohup /Applications/Parsec.app/Contents/MacOS/parsecd > /tmp/parsec.log 2>&1 &
    PARSECD_PID=$!
    echo "   Started parsecd with PID: ${PARSECD_PID}"
    sleep 5
    
    if kill -0 ${PARSECD_PID} 2>/dev/null; then
        PARSEC_STARTED=true
        echo "   ✓ parsecd is running"
    else
        echo "   ✗ parsecd exited, checking logs:"
        cat /tmp/parsec.log 2>/dev/null | head -20 || echo "     No logs available"
    fi
fi

# Method 3: Try with session_id as environment variable
if [ "$PARSEC_STARTED" = false ]; then
    echo "   Trying: parsecd with PARSEC_SESSION_ID env"
    PARSECD_SESSION_ID="${PARSEC_SESSION_ID}" nohup /Applications/Parsec.app/Contents/MacOS/parsecd > /tmp/parsec2.log 2>&1 &
    sleep 5
    
    if pgrep -f "parsecd" > /dev/null; then
        PARSEC_STARTED=true
        echo "   ✓ parsecd is running with session env"
    fi
fi

# Show all running processes that might be Parsec
echo ""
echo "🔍 Parsec-related processes:"
ps aux | grep -i parsec | grep -v grep || echo "   None found"

# Check for any error logs
if [ -f "/tmp/parsec.log" ]; then
    echo ""
    echo "📋 Parsec log output:"
    cat /tmp/parsec.log 2>/dev/null | head -30 || echo "   Empty"
fi

# Final verification
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "                    FINAL STATUS CHECK"
echo "═══════════════════════════════════════════════════════════════════"

# Check if any Parsec process is running
PARSEC_RUNNING=false
if pgrep -f "parsecd" > /dev/null; then
    PARSEC_RUNNING=true
elif pgrep -f "Parsec" > /dev/null; then
    PARSEC_RUNNING=true
fi

if [ "$PARSEC_RUNNING" = true ]; then
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
    echo "⚠️ Note: If the host does not appear after a few minutes,"
    echo "   the session authentication may have failed. Check that your"
    echo "   PARSEC_SESSION_ID secret is valid and not expired."
    echo ""
    
    # Try to show Parsec's auth status if available
    if [ -f "${PARSEC_CONFIG_DIR}/user.bin" ]; then
        echo "✓ User data file exists - authentication may be cached"
    else
        echo "⚠️ No user.bin found - you may need to authenticate manually"
        echo "   on first connection attempt."
    fi
    echo ""
else
    echo ""
    echo "❌ Parsec process NOT running!"
    echo ""
    echo "📋 Diagnostic Information:"
    echo ""
    
    # Check if the binary exists and is executable
    if [ -x "/Applications/Parsec.app/Contents/MacOS/parsecd" ]; then
        echo "   ✓ parsecd binary exists and is executable"
    else
        echo "   ✗ parsecd binary missing or not executable"
    fi
    
    # Check for permissions issues
    echo ""
    echo "   Checking for macOS security restrictions..."
    
    # Try running parsecd and capture error
    /Applications/Parsec.app/Contents/MacOS/parsecd --help 2>&1 | head -10 || echo "   parsecd --help failed"
    
    echo ""
    echo "   This is likely caused by macOS VM security restrictions."
    echo "   GitHub Actions macOS runners may block GUI applications."
    echo ""
    echo "💡 Alternatives:"
    echo "   • Use RustDesk workflow (rustdesk-session.yml) - CONFIRMED WORKING!"
    echo "   • Self-hosted macOS runner with full permissions"
    echo ""
fi
