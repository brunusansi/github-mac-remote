#!/bin/bash
# setup-vnc.sh - Configure macOS Screen Sharing (VNC)

set -e

# Generate random password
VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)}"
VNC_USER="${VNC_USER:-runner}"

echo "🖥️  Configuring Screen Sharing (VNC)..."

# Enable Screen Sharing
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -activate -configure -access -on \
    -restart -agent -privs -all

# Enable VNC with password
sudo defaults write /Library/Preferences/com.apple.VNCSettings.txt Enabled -bool true

# Set VNC password (stored in keychain)
echo "${VNC_PASSWORD}" | sudo /usr/bin/security add-generic-password -a vnc -s com.apple.VNCServer -w "${VNC_PASSWORD}" /Library/Keychains/System.keychain 2>/dev/null || true

# Alternative: Set password via directory services
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -configure -clientopts -setvnclegacy -vnclegacy yes \
    -setvncpw -vncpw "${VNC_PASSWORD}"

# Restart the service
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -restart -agent

# Get the current user for display
CURRENT_USER=$(whoami)

echo ""
echo "✅ VNC configured successfully!"
echo ""
echo "📋 VNC Credentials:"
echo "   User: ${CURRENT_USER}"
echo "   Password: ${VNC_PASSWORD}"
echo "   Port: 5900"
echo ""

# Export for other scripts
export VNC_PASSWORD
export VNC_USER="${CURRENT_USER}"
export VNC_PORT=5900
