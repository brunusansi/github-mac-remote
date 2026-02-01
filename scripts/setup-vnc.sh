#!/bin/bash
# setup-vnc.sh - Configure macOS Screen Sharing (VNC)

set -e

# Generate random password if not provided
VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)}"

echo "🖥️  Configuring VNC Access..."

# Get current user
CURRENT_USER=$(whoami)

# Method 1: Enable Remote Management / Screen Sharing via kickstart
echo "📡 Enabling Remote Management..."
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -activate \
    -configure -allowAccessFor -allUsers \
    -configure -clientopts -setvnclegacy -vnclegacy yes \
    -configure -clientopts -setvncpw -vncpw "${VNC_PASSWORD}" \
    -restart -agent -privs -all 2>/dev/null || true

# Method 2: Alternative - use dscl to set VNC password
echo "🔐 Setting VNC password..."
echo "${VNC_PASSWORD}" | sudo /usr/bin/dscl . -passwd /Users/${CURRENT_USER} 2>/dev/null || true

# Method 3: Create a simple VNC server using macOS built-in
# Enable Screen Sharing
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false 2>/dev/null || true
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

# Alternative: Start VNC via AppleScript Remote Desktop
echo "🚀 Starting Screen Sharing service..."
sudo launchctl enable system/com.apple.screensharing 2>/dev/null || true
sudo launchctl start com.apple.screensharing 2>/dev/null || true

# Set login password (this is what VNC will use on macOS)
echo "🔑 Configuring user password for VNC login..."
# On GitHub Actions, we need to set the user password
echo "${CURRENT_USER}:${VNC_PASSWORD}" | sudo chpasswd 2>/dev/null || \
    sudo dscl . -passwd /Users/${CURRENT_USER} "${VNC_PASSWORD}" 2>/dev/null || \
    echo "⚠️  Could not set user password directly"

# Verify screen sharing is enabled
echo "🔍 Checking Screen Sharing status..."
if sudo launchctl list | grep -q screensharing; then
    echo "✅ Screen Sharing service is running"
else
    echo "⚠️  Screen Sharing might not be fully enabled"
    # Try one more method
    sudo systemsetup -setremotelogin on 2>/dev/null || true
fi

# Display info
echo ""
echo "✅ VNC Setup Complete!"
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    VNC CREDENTIALS                               ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "   👤 Username: ${CURRENT_USER}"
echo "   🔐 Password: ${VNC_PASSWORD}"
echo "   🔌 Port: 5900"
echo ""
echo "   Note: Use the username AND password when connecting."
echo "   Some VNC clients may ask for both."
echo ""

# Export for other scripts
export VNC_PASSWORD
export VNC_USER="${CURRENT_USER}"
export VNC_PORT=5900

# Save to file for artifact
mkdir -p /tmp/vnc-credentials
echo "Username: ${CURRENT_USER}" > /tmp/vnc-credentials/info.txt
echo "Password: ${VNC_PASSWORD}" >> /tmp/vnc-credentials/info.txt
echo "Port: 5900" >> /tmp/vnc-credentials/info.txt
