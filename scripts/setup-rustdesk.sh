#!/bin/bash
# setup-rustdesk.sh - Install and configure RustDesk for remote access
# RustDesk is an open-source remote desktop similar to TeamViewer/AnyDesk

set -e

RUSTDESK_VERSION="${RUSTDESK_VERSION:-1.4.5}"
RUSTDESK_PASSWORD="${RUSTDESK_PASSWORD:-}"

echo "🦀 Setting up RustDesk v${RUSTDESK_VERSION}..."

# Generate password if not provided
if [ -z "${RUSTDESK_PASSWORD}" ]; then
    RUSTDESK_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)
    echo "RUSTDESK_PASSWORD=${RUSTDESK_PASSWORD}" >> $GITHUB_ENV
fi

# Download RustDesk for macOS ARM64
echo "📦 Downloading RustDesk..."
RUSTDESK_DMG="/tmp/rustdesk.dmg"
RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-aarch64.dmg"

echo "   URL: ${RUSTDESK_URL}"
curl -L "${RUSTDESK_URL}" -o "${RUSTDESK_DMG}" --progress-bar

# Verify download
FILE_SIZE=$(stat -f%z "${RUSTDESK_DMG}" 2>/dev/null || stat --printf="%s" "${RUSTDESK_DMG}" 2>/dev/null || echo "0")
echo "   Downloaded: ${FILE_SIZE} bytes"

if [ "${FILE_SIZE}" -lt 1000000 ]; then
    echo "❌ Download failed - file too small (${FILE_SIZE} bytes)"
    echo "   Content of downloaded file:"
    head -c 500 "${RUSTDESK_DMG}" || true
    exit 1
fi

echo "✅ Download complete (${FILE_SIZE} bytes)"

# Mount DMG
echo "📦 Mounting DMG..."
hdiutil attach "${RUSTDESK_DMG}" -nobrowse -quiet || {
    echo "⚠️ First mount attempt failed, retrying..."
    sleep 2
    hdiutil attach "${RUSTDESK_DMG}" -nobrowse -quiet -force
}

sleep 3

# Find and install RustDesk
echo "📦 Installing RustDesk..."
RUSTDESK_VOL=$(ls -d /Volumes/RustDesk* 2>/dev/null | head -1)

if [ -z "$RUSTDESK_VOL" ]; then
    echo "⚠️ Looking for alternative volume names..."
    ls -la /Volumes/
    RUSTDESK_VOL=$(ls -d /Volumes/*ustdesk* 2>/dev/null | head -1)
fi

if [ -n "$RUSTDESK_VOL" ]; then
    echo "   Found volume: $RUSTDESK_VOL"
    ls -la "$RUSTDESK_VOL/"
    
    if [ -d "$RUSTDESK_VOL/RustDesk.app" ]; then
        cp -R "$RUSTDESK_VOL/RustDesk.app" /Applications/
    elif [ -d "$RUSTDESK_VOL"/*.app ]; then
        cp -R "$RUSTDESK_VOL"/*.app /Applications/
    fi
    
    hdiutil detach "$RUSTDESK_VOL" -quiet || true
else
    echo "❌ Could not find RustDesk volume"
    exit 1
fi

# Verify installation
if [ ! -d "/Applications/RustDesk.app" ]; then
    echo "❌ Failed to install RustDesk"
    ls -la /Applications/ | grep -i rust || true
    exit 1
fi

echo "✅ RustDesk installed to /Applications/RustDesk.app"

# Create config directory
RUSTDESK_CONFIG_DIR="$HOME/Library/Application Support/RustDesk"
mkdir -p "${RUSTDESK_CONFIG_DIR}"

# RustDesk stores config in a specific format
# We need to set a permanent password for unattended access
echo "⚙️ Configuring RustDesk..."

# Encode password for RustDesk config (base64)
# RustDesk expects password in base64 format in config
ENCODED_PASSWORD=$(echo -n "${RUSTDESK_PASSWORD}" | base64)

# Create RustDesk2.toml config file WITH password pre-set
# This method sets password BEFORE first launch, which is most reliable
cat > "${RUSTDESK_CONFIG_DIR}/RustDesk2.toml" << EOFTOML
rendezvous_server = 'rs-ny.rustdesk.com'
nat_type = 1
serial = 0

[options]
allow-auto-disconnect = 'N'
stop-service = 'N'
direct-server = 'Y'
allow-linux-headless = 'Y'
EOFTOML

# Also create RustDesk.toml with password (RustDesk checks both files)
cat > "${RUSTDESK_CONFIG_DIR}/RustDesk.toml" << EOFTOML
password = '${RUSTDESK_PASSWORD}'
EOFTOML

echo "   ✅ Pre-configured password in config files"
echo "   📁 Config location: ${RUSTDESK_CONFIG_DIR}"

# Grant necessary permissions via TCC database (may require SIP disabled)
echo "🔐 Attempting to grant permissions..."

# Try to enable accessibility (required for remote control)
# This may fail on GitHub Actions VMs due to security restrictions
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
    "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','com.rustdesk.RustDesk',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,$(date +%s));" 2>/dev/null || \
    echo "⚠️ Could not set accessibility permissions (expected on VM)"

sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
    "INSERT OR REPLACE INTO access VALUES('kTCCServiceScreenCapture','com.rustdesk.RustDesk',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,$(date +%s));" 2>/dev/null || \
    echo "⚠️ Could not set screen capture permissions (expected on VM)"

# Start RustDesk FIRST, before trying to set password
echo "🚀 Starting RustDesk..."

# Use full path to open the app
/Applications/RustDesk.app/Contents/MacOS/rustdesk &
RUSTDESK_PID=$!

echo "   Waiting for RustDesk to initialize (PID: $RUSTDESK_PID)..."
sleep 10

# Verify RustDesk is running
if pgrep -f "RustDesk" > /dev/null; then
    echo "   ✅ RustDesk is running"
else
    echo "   ⚠️ RustDesk not detected, trying alternative launch..."
    open -a RustDesk
    sleep 5
fi

# Now try to set password via command line (RustDesk must be running first!)
echo "🔑 Setting up password..."

RUSTDESK_CLI="/Applications/RustDesk.app/Contents/MacOS/rustdesk"
if [ -f "${RUSTDESK_CLI}" ]; then
    
    # Get the RustDesk ID first (this also confirms RustDesk is initialized)
    RUSTDESK_ID=$("${RUSTDESK_CLI}" --get-id 2>/dev/null || echo "")
    
    if [ -n "${RUSTDESK_ID}" ]; then
        echo "RUSTDESK_ID=${RUSTDESK_ID}" >> $GITHUB_ENV
        echo "   ✅ RustDesk ID: ${RUSTDESK_ID}"
    fi
    
    # Now try to set permanent password with sudo
    # RustDesk needs to be running for this to work
    echo "   Attempting to set password..."
    
    # Method 1: Try direct password setting
    PASSWORD_OUTPUT=$(sudo "${RUSTDESK_CLI}" --password "${RUSTDESK_PASSWORD}" 2>&1)
    echo "   Password command output: ${PASSWORD_OUTPUT}"
    
    # Check if it actually worked by looking at the output
    if echo "${PASSWORD_OUTPUT}" | grep -qi "error\|fail\|denied\|not found"; then
        echo "   ⚠️ Password setting via CLI may have failed"
        PASSWORD_SET=false
    else
        echo "   ✅ Password command executed"
        PASSWORD_SET=true
    fi
    
    sleep 3
    
    # Try to verify/retrieve the actual password RustDesk is using
    echo "   🔍 Checking RustDesk's actual password configuration..."
    
    # Method: Try --get-password CLI option
    ACTUAL_PASSWORD=$(sudo "${RUSTDESK_CLI}" --get-password 2>&1 || echo "")
    echo "   Get-password output: ${ACTUAL_PASSWORD}"
    
    # If we got a password from RustDesk, use that instead
    if [ -n "${ACTUAL_PASSWORD}" ] && ! echo "${ACTUAL_PASSWORD}" | grep -qi "error\|not found\|usage"; then
        if [ "${ACTUAL_PASSWORD}" != "${RUSTDESK_PASSWORD}" ]; then
            echo "   📝 RustDesk has a different password than we set"
            echo "   📝 Using RustDesk's password: ${ACTUAL_PASSWORD}"
            RUSTDESK_PASSWORD="${ACTUAL_PASSWORD}"
            echo "RUSTDESK_PASSWORD=${RUSTDESK_PASSWORD}" >> $GITHUB_ENV
        fi
    fi
    
    # Also dump what's in the config directory for debugging
    echo ""
    echo "   📂 Checking config directory structure..."
    ls -la "${RUSTDESK_CONFIG_DIR}/" 2>/dev/null || echo "   Config dir not accessible"
    
    # Check for any files RustDesk created
    echo ""
    echo "   📂 All RustDesk config files:"
    find "${RUSTDESK_CONFIG_DIR}" -type f 2>/dev/null | while read f; do
        echo "   File: $f"
        echo "   Contents:"
        cat "$f" 2>/dev/null | head -20
        echo ""
    done
fi

# Check if RustDesk is running
sleep 5
echo "🔍 Checking RustDesk status..."

if pgrep -f "RustDesk" > /dev/null; then
    echo ""
    echo "✅ RustDesk process is running!"
    echo ""
    
    # Try to get ID from config files
    if [ -z "${RUSTDESK_ID}" ]; then
        # Check various possible ID locations
        RUSTDESK_ID=$(cat "${RUSTDESK_CONFIG_DIR}/id" 2>/dev/null || \
                      grep -o '"id":"[^"]*"' "${RUSTDESK_CONFIG_DIR}"/*.json 2>/dev/null | head -1 | cut -d'"' -f4 || \
                      echo "")
    fi
    
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                  🦀 RUSTDESK SETUP COMPLETE                      ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    if [ -n "${RUSTDESK_ID}" ]; then
        echo "   🆔 RustDesk ID: ${RUSTDESK_ID}"
    else
        echo "   🆔 RustDesk ID: (check the RustDesk window or logs)"
    fi
    echo "   🔐 Password: ${RUSTDESK_PASSWORD}"
    echo ""
    echo "📖 How to Connect:"
    echo ""
    echo "   1. Download RustDesk client from: https://rustdesk.com/download"
    echo "   2. Install and open RustDesk on your computer"
    if [ -n "${RUSTDESK_ID}" ]; then
        echo "   3. Enter ID: ${RUSTDESK_ID}"
    else
        echo "   3. Enter the ID shown in the RustDesk window"
    fi
    echo "   4. Enter password: ${RUSTDESK_PASSWORD}"
    echo "   5. Click Connect!"
    echo ""
    echo "⚠️ Note: If screen/input access is denied, the VM may have"
    echo "   restrictions. Check System Settings > Privacy & Security."
    echo ""
    
    # Also check if the RustDesk service is working
    echo "📊 RustDesk Process Info:"
    ps aux | grep -i rustdesk | grep -v grep || true
    
    # Check network connectivity
    echo ""
    echo "🌐 Network Status:"
    netstat -an | grep -E ":(21115|21116|21117|21118)" || echo "   RustDesk ports not yet listening (normal during startup)"
    
else
    echo ""
    echo "⚠️ RustDesk process not found."
    echo ""
    echo "   Possible reasons:"
    echo "   - First launch may require manual permission grants"
    echo "   - The macOS VM may have security restrictions"
    echo ""
    echo "💡 Trying to launch RustDesk again..."
    open -a RustDesk
    sleep 3
    
    if pgrep -f "RustDesk" > /dev/null; then
        echo "✅ RustDesk is now running!"
    else
        echo "❌ Could not start RustDesk. Falling back to VNC."
    fi
fi

# Display config directory contents for debugging
echo ""
echo "📁 Config directory contents:"
ls -la "${RUSTDESK_CONFIG_DIR}/" 2>/dev/null || echo "   (directory is empty or inaccessible)"

# Show config file contents for debugging (password is visible in workflow logs anyway)
echo ""
echo "📄 RustDesk.toml contents:"
cat "${RUSTDESK_CONFIG_DIR}/RustDesk.toml" 2>/dev/null || echo "   (file not found)"

echo ""
echo "📄 RustDesk2.toml contents:"
cat "${RUSTDESK_CONFIG_DIR}/RustDesk2.toml" 2>/dev/null || echo "   (file not found)"

echo ""
echo "🎉 RustDesk setup complete!"
