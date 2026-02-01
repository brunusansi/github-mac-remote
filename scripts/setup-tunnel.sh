#!/bin/bash
# setup-tunnel.sh - Create public tunnel for remote access

set -e

TUNNEL_TYPE="${TUNNEL_TYPE:-cloudflared}"
VNC_PORT="${VNC_PORT:-5900}"
SSH_PORT="${SSH_PORT:-22}"

echo "🚇 Setting up tunnel (${TUNNEL_TYPE})..."

# Function to install cloudflared
install_cloudflared() {
    if ! command -v cloudflared &> /dev/null; then
        echo "📦 Installing cloudflared..."
        brew install cloudflared
    fi
}

# Function to install ngrok
install_ngrok() {
    if ! command -v ngrok &> /dev/null; then
        echo "📦 Installing ngrok..."
        brew install ngrok/ngrok/ngrok
    fi
}

# Function to start cloudflared tunnel
start_cloudflared() {
    install_cloudflared
    
    echo "🌐 Starting cloudflared tunnel for VNC (port ${VNC_PORT})..."
    
    # Start tunnel in background and capture URL
    cloudflared tunnel --url tcp://localhost:${VNC_PORT} 2>&1 | tee /tmp/tunnel_vnc.log &
    TUNNEL_PID_VNC=$!
    
    # Wait for tunnel URL
    sleep 5
    
    # Extract the tunnel URL
    VNC_TUNNEL_URL=$(grep -o 'https://[^[:space:]]*\.trycloudflare\.com' /tmp/tunnel_vnc.log | head -1 || echo "")
    
    if [ -z "$VNC_TUNNEL_URL" ]; then
        # Try TCP format
        VNC_TUNNEL_URL=$(grep -o 'tcp://[^[:space:]]*' /tmp/tunnel_vnc.log | head -1 || echo "")
    fi
    
    echo ""
    echo "✅ Cloudflared tunnel active!"
    echo ""
    echo "📋 Connection Details:"
    echo "   VNC URL: ${VNC_TUNNEL_URL:-Check /tmp/tunnel_vnc.log}"
    echo ""
    echo "   To connect, you may need cloudflared on your local machine:"
    echo "   cloudflared access tcp --hostname <tunnel-url> --url localhost:5900"
    echo ""
    
    # Also start SSH tunnel if SSH is available
    if [ -f /etc/ssh/sshd_config ]; then
        echo "🔐 Starting cloudflared tunnel for SSH (port ${SSH_PORT})..."
        cloudflared tunnel --url tcp://localhost:${SSH_PORT} 2>&1 | tee /tmp/tunnel_ssh.log &
        TUNNEL_PID_SSH=$!
        sleep 3
        SSH_TUNNEL_URL=$(grep -o 'https://[^[:space:]]*\.trycloudflare\.com' /tmp/tunnel_ssh.log | head -1 || echo "")
        echo "   SSH URL: ${SSH_TUNNEL_URL:-Check /tmp/tunnel_ssh.log}"
    fi
    
    # Export for other scripts
    export VNC_TUNNEL_URL
    export SSH_TUNNEL_URL
    export TUNNEL_PID_VNC
    export TUNNEL_PID_SSH
}

# Function to start ngrok tunnel
start_ngrok() {
    install_ngrok
    
    # Check for auth token
    if [ -n "${NGROK_AUTH_TOKEN}" ]; then
        ngrok config add-authtoken "${NGROK_AUTH_TOKEN}"
    fi
    
    echo "🌐 Starting ngrok tunnel for VNC (port ${VNC_PORT})..."
    
    ngrok tcp ${VNC_PORT} --log=stdout > /tmp/tunnel_vnc.log 2>&1 &
    TUNNEL_PID_VNC=$!
    
    sleep 5
    
    # Get tunnel URL from ngrok API
    VNC_TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")
    
    echo ""
    echo "✅ ngrok tunnel active!"
    echo ""
    echo "📋 Connection Details:"
    echo "   VNC URL: ${VNC_TUNNEL_URL:-Check ngrok dashboard}"
    echo ""
    
    export VNC_TUNNEL_URL
    export TUNNEL_PID_VNC
}

# Main logic
case "${TUNNEL_TYPE}" in
    cloudflared)
        start_cloudflared
        ;;
    ngrok)
        start_ngrok
        ;;
    *)
        echo "❌ Unknown tunnel type: ${TUNNEL_TYPE}"
        echo "   Supported: cloudflared, ngrok"
        exit 1
        ;;
esac

echo ""
echo "🔗 Tunnel is running. Keep this process alive to maintain connection."
