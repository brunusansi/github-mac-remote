#!/bin/bash
# install-parsec.sh - Install Parsec for optional manual use
# Parsec is installed but NOT configured - user can log in manually via RustDesk

set -e

echo "🎮 Installing Parsec (for optional manual use)..."

# Download Parsec
PARSEC_PKG="/tmp/parsec.pkg"

echo "📦 Downloading Parsec..."
curl -L "https://builds.parsec.app/package/parsec-macos.pkg" -o "${PARSEC_PKG}" --progress-bar --fail

# Verify download
FILE_SIZE=$(stat -f%z "${PARSEC_PKG}" 2>/dev/null || echo "0")

if [ "${FILE_SIZE}" -lt 1000000 ]; then
    echo "⚠️ Parsec download failed - skipping installation"
    exit 0
fi

echo "✅ Download complete (${FILE_SIZE} bytes)"

# Install
echo "📦 Installing Parsec..."
sudo installer -pkg "${PARSEC_PKG}" -target / || {
    echo "⚠️ Parsec installation failed - skipping"
    exit 0
}

# Verify installation
if [ -d "/Applications/Parsec.app" ]; then
    echo "✅ Parsec installed to /Applications/Parsec.app"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎮 Parsec is installed but NOT configured."
    echo ""
    echo "   To use Parsec:"
    echo "   1. Connect via RustDesk first"
    echo "   2. Open Parsec from Applications"
    echo "   3. Log in with your Parsec account"
    echo "   4. Enable hosting in Parsec settings"
    echo "   5. Connect from your other device"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "⚠️ Parsec installation could not be verified"
fi

# Cleanup
rm -f "${PARSEC_PKG}"

echo ""
echo "✅ Parsec installation complete"
