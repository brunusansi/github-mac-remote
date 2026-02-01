# 🍎 GitHub Mac Remote

> **Turn GitHub Actions runners into accessible remote Mac Minis**

Access Mac Minis with Apple Silicon (M1/M2/M3) through GitHub Actions. Similar to MacStadium, but using GitHub's infrastructure.

[![Start Mac Session](https://img.shields.io/badge/▶️_Start_Mac_Session-blue?style=for-the-badge)](../../actions/workflows/mac-session.yml)
[![Extended Session](https://img.shields.io/badge/🔗_Extended_Session-green?style=for-the-badge)](../../actions/workflows/extended-session.yml)
[![Parsec Session](https://img.shields.io/badge/🎮_Parsec_Session-purple?style=for-the-badge)](../../actions/workflows/parsec-session.yml)

---

## ✨ Features

- 🖥️ **Real Mac ARM64** - Not a VM, physical Mac Mini with Apple Silicon
- 🌐 **Remote Access** - Via VNC (native) or Parsec
- ⏱️ **Configurable Sessions** - From 1h to 6h (or more with chaining)
- 🔗 **Extended Sessions** - Auto-chain for sessions >6h
- 🔐 **Secure Credentials** - Password stored in private artifact
- 📊 **Multiple Tiers** - Standard, Large, XLarge

---

## 🚀 Quick Start

### 1. Use this repository

**Option A: Fork** (recommended)
```
Fork this repository to your account
```

**Option B: Template**
```
Use as a template to create a new repository
```

### 2. Start a session

1. Go to **Actions** → **"🍎 Start Mac Session"**
2. Click **"Run workflow"**
3. Configure:
   - **Duration**: Session time (1-6 hours)
   - **Runner size**: Mac size (see table below)
   - **Tunnel type**: cloudflared (recommended) or ngrok
4. Click **"Run workflow"**

### 3. Get credentials

1. Wait for the workflow to reach "Keep Session Alive" step
2. Go to the **Summary** tab
3. Download the **"connection-credentials"** artifact
4. Open the `.txt` file to see VNC password

### 4. Connect

#### Install cloudflared (one time):

**Windows (PowerShell as Admin):**
```powershell
winget install Cloudflare.cloudflared
```

**macOS:**
```bash
brew install cloudflared
```

**Linux:**
```bash
# Debian/Ubuntu
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

#### Create local tunnel:
```bash
cloudflared access tcp --hostname <TUNNEL_URL_FROM_LOGS> --url localhost:5900
```

#### Connect VNC client:
- **Windows**: Use [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) → Connect to `localhost:5900`
- **macOS**: Open Finder → Go → Connect to Server → `vnc://localhost:5900`
- **Linux**: Use Remmina or `vncviewer localhost:5900`

Enter the password from the artifact file.

---

## 📊 Hardware Tiers

| Tier | Runner | vCPUs | RAM | Chip | Plans |
|------|--------|-------|-----|------|-------|
| **Standard** | `macos-14` | 3 | 7 GB | M1 | Free, Pro, Team, Enterprise |
| **Large** | `macos-14-large` | 12 | 30 GB | M1 Pro | Team, Enterprise |
| **XLarge** | `macos-14-xlarge` | 24 | 70 GB | M1 Max | Enterprise |

> ⚠️ Large and XLarge runners require paid GitHub plans

---

## ⏱️ Time Limits

| Plan | Minutes/month | Max per session |
|------|---------------|-----------------|
| **Free** | 2,000 min | 6 hours |
| **Pro** | 3,000 min | 6 hours |
| **Team** | 3,000 min | 6 hours |
| **Enterprise** | Custom | 6 hours |

### Extended Sessions (>6 hours)

Use the **"🔗 Extended Mac Session"** workflow for longer sessions:

1. Set `max_chains` (max 3 = 18 hours total)
2. System automatically triggers new session before timeout
3. New credentials generated for each chain
4. ~30 seconds downtime between chains

---

## 🎮 Parsec (Optional - Better Performance)

Parsec provides lower latency and better video quality than VNC.

### Setup Parsec (Windows)

#### Step 1: Get your Session ID

**Option A: From Parsec app files**

1. Open File Explorer
2. Navigate to `%AppData%\Parsec\`
3. Look for your session info in the config files

**Option B: Via PowerShell (recommended)**

```powershell
# Replace with your actual credentials
$body = @{
    email = "your@email.com"
    password = "yourpassword"
    tfa = "123456"  # Your 2FA code (get it fresh, expires in 30 seconds!)
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri 'https://kessel-api.parsecgaming.com/v1/auth' -Method POST -ContentType 'application/json' -Body $body
$response.session_id
```

**Option C: Via Command Prompt (curl)**

First, install curl or use Git Bash:
```bash
curl -X POST https://kessel-api.parsecgaming.com/v1/auth \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"your@email.com\",\"password\":\"yourpassword\",\"tfa\":\"123456\"}"
```

> ⚠️ **Important**: The `tfa` field is your 2FA authenticator code. Get it right before running the command - it expires in 30 seconds!

#### Step 2: Add to GitHub Secrets

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Name: `PARSEC_SESSION_ID`
4. Value: Your session_id from Step 1
5. Click **"Add secret"**

#### Step 3: Run Parsec Workflow

1. Go to **Actions** → **"🎮 Parsec Mac Session"**
2. Click **"Run workflow"**
3. Wait for it to start
4. Open Parsec app on your computer
5. Look for the host named `GitHub-Mac-XXXXX` in your computers list
6. Click to connect!

### Parsec vs VNC Comparison

| Feature | VNC | Parsec |
|---------|-----|--------|
| Video Quality | Good | Excellent |
| Latency | Medium | Low |
| Audio | No | Yes |
| Gamepad Support | No | Yes |
| Requires Account | No | Yes |
| Setup Complexity | Easy | Medium |

---

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── mac-session.yml        # Simple session
│       ├── extended-session.yml   # Session with chaining
│       └── parsec-session.yml     # Session with Parsec
├── scripts/
│   ├── setup-vnc.sh              # Configures Screen Sharing
│   ├── setup-tunnel.sh           # Starts tunnel
│   ├── setup-parsec.sh           # Configures Parsec
│   ├── keep-alive.sh             # Keeps session active
│   ├── show-credentials.sh       # Shows credentials
│   └── system-info.sh            # System info
├── configs/
│   └── hardware-tiers.json       # Hardware configurations
└── README.md
```

---

## 🔧 Advanced Configuration

### Available Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `PARSEC_SESSION_ID` | Parsec session ID | Only for Parsec |
| `NGROK_AUTH_TOKEN` | ngrok auth token (increases limits) | No |

### Environment Variables

Workflows use these variables (configurable via inputs):

- `SESSION_DURATION`: Duration in hours
- `TUNNEL_TYPE`: `cloudflared` or `ngrok`
- `VNC_PASSWORD`: Auto-generated per session

---

## 🔐 Security

### Credential Protection

- **VNC Password**: Stored in private artifact (not visible in public logs)
- **Tunnel URL**: Visible in logs (needed for connection)
- **Session**: Ephemeral - everything is destroyed when workflow ends

### For Public Repositories

If your repository is public:
1. Credentials are saved to a downloadable artifact
2. Only repository collaborators can download artifacts
3. Tunnel URL is public but useless without the password

### Recommendation

For maximum security, make your repository **private**. This ensures all logs and artifacts are only visible to you.

---

## ❓ Troubleshooting

### "Cannot connect to VNC"

1. Make sure cloudflared is running locally
2. Verify you're using the correct tunnel URL
3. Try `localhost:5900` in VNC client
4. Check if the workflow is still in "Keep Session Alive" step

### "Tunnel won't start"

1. Check workflow logs for errors
2. Try ngrok as an alternative
3. For ngrok, configure `NGROK_AUTH_TOKEN` secret

### "Parsec host not appearing"

1. Confirm `PARSEC_SESSION_ID` is correct
2. Make sure you're logged into the same Parsec account
3. Wait a few seconds and refresh
4. Check if the workflow completed the Parsec setup step

### "Session ended early"

1. GitHub has a 6h max timeout
2. Use "Extended Session" for longer sessions
3. Check if keep-alive is generating output

### "Authentication error" in VNC

1. Make sure you're using the password from the artifact file
2. The password is case-sensitive
3. Try downloading the artifact again

---

## ⚖️ Responsible Use

This project is for **legitimate development and testing**:

- ✅ Testing iOS/macOS apps
- ✅ Occasional development work
- ✅ CI/CD that requires macOS environment
- ❌ 24/7 usage (use MacStadium for that)
- ❌ Mining or abusive workloads

GitHub may suspend accounts that abuse resources.

---

## 📄 License

MIT License - Use freely, but at your own risk.

---

## 🙏 Credits

- **GitHub Actions** - Infrastructure
- **Cloudflare** - Free tunnels via cloudflared
- **Parsec** - High-performance streaming

---

<p align="center">
  <b>Made with ❤️ for the community</b><br>
  <sub>Star ⭐ if this project helped you!</sub>
</p>
