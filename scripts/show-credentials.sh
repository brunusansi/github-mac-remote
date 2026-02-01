#!/bin/bash
# show-credentials.sh - Display all connection credentials

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              🍎 GITHUB MAC REMOTE - CONNECTION INFO              ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# System info
echo "📊 System Information:"
echo "   ├─ Hostname: $(hostname)"
echo "   ├─ macOS: $(sw_vers -productVersion)"
echo "   ├─ Chip: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)"
echo "   ├─ Cores: $(sysctl -n hw.ncpu)"
echo "   ├─ Memory: $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
echo "   └─ User: $(whoami)"
echo ""

# VNC credentials
if [ -n "${VNC_PASSWORD}" ]; then
    echo "🖥️  VNC Connection:"
    echo "   ├─ Local Port: 5900"
    echo "   ├─ User: $(whoami)"
    echo "   └─ Password: ${VNC_PASSWORD}"
    echo ""
fi

# Tunnel info
if [ -n "${VNC_TUNNEL_URL}" ]; then
    echo "🌐 Tunnel (VNC):"
    echo "   └─ URL: ${VNC_TUNNEL_URL}"
    echo ""
fi

if [ -n "${SSH_TUNNEL_URL}" ]; then
    echo "🔐 Tunnel (SSH):"
    echo "   └─ URL: ${SSH_TUNNEL_URL}"
    echo ""
fi

# Connection instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 How to Connect:"
echo ""
echo "   Option 1: Direct VNC (if using ngrok or similar)"
echo "   ─────────────────────────────────────────────────"
echo "   1. Open your VNC client (RealVNC, TightVNC, etc.)"
echo "   2. Connect to the tunnel URL shown above"
echo "   3. Enter the VNC password when prompted"
echo ""
echo "   Option 2: Cloudflared Tunnel"
echo "   ────────────────────────────"
echo "   1. Install cloudflared on your local machine"
echo "   2. Run: cloudflared access tcp --hostname <tunnel-url> --url localhost:5900"
echo "   3. Connect your VNC client to localhost:5900"
echo "   4. Enter the VNC password when prompted"
echo ""
echo "   Option 3: SSH Access"
echo "   ────────────────────"
echo "   1. For cloudflared: cloudflared access tcp --hostname <ssh-url> --url localhost:2222"
echo "   2. Then: ssh -p 2222 $(whoami)@localhost"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
