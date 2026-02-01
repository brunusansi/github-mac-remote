#!/bin/bash
# setup-vnc.sh - Configure VNC access on macOS (works on VMs)

set -e

# Generate random password if not provided
VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)}"
VNC_PORT="${VNC_PORT:-5900}"

echo "🖥️ Configuring VNC Access..."
echo ""

# Get current user
CURRENT_USER=$(whoami)
echo "👤 Current user: ${CURRENT_USER}"

# Method 1: Set user password (VNC on macOS uses login password)
echo "🔐 Setting up authentication..."

# Try to set password using dscl
if sudo dscl . -passwd /Users/${CURRENT_USER} "${VNC_PASSWORD}" 2>/dev/null; then
    echo "✅ User password set via dscl"
else
    echo "⚠️ Could not set password via dscl, trying alternative..."
fi

# Method 2: Enable Remote Desktop / Screen Sharing
echo "📡 Enabling Screen Sharing..."

# Enable via kickstart (Apple Remote Desktop agent)
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -activate \
    -configure -allowAccessFor -allUsers \
    -configure -clientopts -setvnclegacy -vnclegacy yes \
    -configure -clientopts -setvncpw -vncpw "${VNC_PASSWORD}" \
    -restart -agent -privs -all 2>&1 || echo "⚠️ kickstart returned non-zero (may still work)"

# Method 3: Enable Screen Sharing via launchctl
echo "🔄 Starting Screen Sharing service..."
sudo launchctl enable system/com.apple.screensharing 2>/dev/null || true
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
sudo launchctl start com.apple.screensharing 2>/dev/null || true

# Method 4: Enable via defaults
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false 2>/dev/null || true

# Method 5: Enable SSH as backup
echo "🔗 Enabling SSH..."
sudo systemsetup -setremotelogin on 2>/dev/null || true
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true

# Wait for services to start
sleep 3

# Verify Screen Sharing
echo ""
echo "🔍 Checking services..."

VNC_RUNNING=false
SSH_RUNNING=false

if sudo lsof -i :5900 2>/dev/null | grep -q LISTEN; then
    echo "✅ VNC (port 5900) is listening"
    VNC_RUNNING=true
elif sudo launchctl list | grep -q screensharing; then
    echo "✅ Screen Sharing service is loaded"
    VNC_RUNNING=true
else
    echo "⚠️ VNC may not be fully enabled"
fi

if sudo lsof -i :22 2>/dev/null | grep -q LISTEN; then
    echo "✅ SSH (port 22) is listening"
    SSH_RUNNING=true
fi

# Display credentials
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    🖥️ VNC SETUP COMPLETE                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "🔐 Credentials:"
echo "   ├─ Username: ${CURRENT_USER}"
echo "   ├─ Password: ${VNC_PASSWORD}"
echo "   └─ VNC Port: ${VNC_PORT}"
echo ""
if [ "$SSH_RUNNING" = true ]; then
    echo "🔗 SSH also available with same credentials"
    echo ""
fi
echo "📖 Connection Instructions:"
echo ""
echo "   1. Run cloudflared locally to create tunnel"
echo "   2. Connect VNC client to localhost:5900"
echo "   3. When prompted for authentication:"
echo "      - Some clients: Just enter password"
echo "      - Others: Enter username '${CURRENT_USER}' AND password"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Export for other scripts
export VNC_PASSWORD
export VNC_USER="${CURRENT_USER}"
export VNC_PORT

# Save to temp for artifact
mkdir -p /tmp/vnc-credentials
cat > /tmp/vnc-credentials/connection.txt << EOF
VNC Connection Info
==================

Username: ${CURRENT_USER}
Password: ${VNC_PASSWORD}
Port: ${VNC_PORT}

VNC Running: ${VNC_RUNNING}
SSH Running: ${SSH_RUNNING}
EOF
