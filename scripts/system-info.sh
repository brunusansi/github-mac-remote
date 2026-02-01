#!/bin/bash
# system-info.sh - Display detailed system information

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    🍎 MAC SYSTEM INFORMATION                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# OS Info
echo "📱 Operating System:"
echo "   ├─ macOS Version: $(sw_vers -productVersion)"
echo "   ├─ Build: $(sw_vers -buildVersion)"
echo "   └─ Kernel: $(uname -r)"
echo ""

# Hardware
echo "🔧 Hardware:"
echo "   ├─ Model: $(sysctl -n hw.model 2>/dev/null || echo 'Unknown')"
echo "   ├─ Chip: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)"
echo "   ├─ Architecture: $(uname -m)"
echo "   ├─ Physical Cores: $(sysctl -n hw.physicalcpu)"
echo "   ├─ Logical Cores: $(sysctl -n hw.logicalcpu)"
echo "   └─ Total Cores: $(sysctl -n hw.ncpu)"
echo ""

# Memory
TOTAL_MEM=$(( $(sysctl -n hw.memsize) / 1073741824 ))
echo "💾 Memory:"
echo "   └─ Total RAM: ${TOTAL_MEM} GB"
echo ""

# Storage
echo "💿 Storage:"
df -h / | awk 'NR==2 {print "   ├─ Total: "$2"\n   ├─ Used: "$3"\n   ├─ Available: "$4"\n   └─ Usage: "$5}'
echo ""

# Network
echo "🌐 Network:"
echo "   ├─ Hostname: $(hostname)"
IP_ADDR=$(ipconfig getifaddr en0 2>/dev/null || echo "N/A")
echo "   └─ IP (en0): ${IP_ADDR}"
echo ""

# Installed Tools
echo "🛠️  Development Tools:"
if command -v xcode-select &> /dev/null; then
    XCODE_PATH=$(xcode-select -p 2>/dev/null || echo "Not installed")
    echo "   ├─ Xcode CLI: ${XCODE_PATH}"
fi
if command -v swift &> /dev/null; then
    SWIFT_VER=$(swift --version 2>&1 | head -1)
    echo "   ├─ Swift: ${SWIFT_VER}"
fi
if command -v brew &> /dev/null; then
    BREW_VER=$(brew --version | head -1)
    echo "   ├─ Homebrew: ${BREW_VER}"
fi
if command -v python3 &> /dev/null; then
    PY_VER=$(python3 --version)
    echo "   ├─ Python: ${PY_VER}"
fi
if command -v node &> /dev/null; then
    NODE_VER=$(node --version)
    echo "   ├─ Node.js: ${NODE_VER}"
fi
echo "   └─ ..."
echo ""

# GitHub Actions specific
if [ -n "${GITHUB_ACTIONS}" ]; then
    echo "🔄 GitHub Actions:"
    echo "   ├─ Runner: ${RUNNER_NAME:-Unknown}"
    echo "   ├─ OS: ${RUNNER_OS:-Unknown}"
    echo "   ├─ Arch: ${RUNNER_ARCH:-Unknown}"
    echo "   └─ Workflow: ${GITHUB_WORKFLOW:-Unknown}"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
