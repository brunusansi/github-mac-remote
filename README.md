# 🍎 GitHub Mac Remote

> **Access Apple Silicon Macs remotely through GitHub Actions — RustDesk, VNC, or Parsec**

Turn GitHub Actions macOS runners into remotely accessible desktops. Connect via RustDesk, VNC over Tailscale, or Parsec.

[![RustDesk Session](https://img.shields.io/badge/🦀_Start_Session-RustDesk-orange?style=for-the-badge)](../../actions/workflows/rustdesk-session.yml)
[![VNC Session](https://img.shields.io/badge/🖥️_Start_Session-VNC_Tailscale-blue?style=for-the-badge)](../../actions/workflows/vnc-session.yml)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Real Mac ARM64** | Virtualized Mac Mini with Apple Silicon |
| 🦀 **RustDesk** | Remote access without complex setup |
| 🎮 **Parsec Pre-installed** | Optional low-latency alternative |
| 🔐 **Admin User Created** | Dedicated admin account for system authentication |
| ⏱️ **Configurable Sessions** | From 1h to 6h per session |
| 🔗 **Extended Sessions** | Auto-chaining for >6h sessions |
| 📊 **Multiple Sizes** | Standard, Large, XLarge, Intel (macOS 26) |
| 🔒 **Secure Credentials** | Passwords never shown in logs |
| 🌐 **Unique IP Guarantee** | Each session gets a fresh, unique IP via Cloudflare WARP |
| 🖥️ **macOS VNC** | Full Mac desktop via VNC + Tailscale |
| 📋 **IP Tracking** | Tracks IP history per user to detect duplicates |

---

## 🚀 Quick Start

### Step 1: Fork or Clone

```bash
# Clone the repository
git clone https://github.com/brunusansi/github-mac-remote.git
```

Or **Fork** to your account/organization.

### Step 2: Install RustDesk on your computer

Download from: **https://rustdesk.com/download**

| System | Download |
|--------|----------|
| Windows | [rustdesk-x86_64.exe](https://github.com/rustdesk/rustdesk/releases/latest) |
| macOS Intel | [rustdesk-x86_64.dmg](https://github.com/rustdesk/rustdesk/releases/latest) |
| macOS Apple Silicon | [rustdesk-aarch64.dmg](https://github.com/rustdesk/rustdesk/releases/latest) |
| Linux | [.deb](https://github.com/rustdesk/rustdesk/releases/latest) / [.AppImage](https://github.com/rustdesk/rustdesk/releases/latest) |

### Step 3: Start a session

1. Go to **Actions** → **"🦀 RustDesk Mac Session"**
2. Click **"Run workflow"**
3. Configure:
   - **Duration**: Session time (1-6 hours)
   - **macOS Version**: Choose 14 (Sonoma), 15 (Sequoia), or 26 (Tahoe)
   - **Runner size**: Mac size (see table below)
   - **Unique IP**: Enable to guarantee a fresh IP via Cloudflare WARP VPN
4. Click **"Run workflow"**

### Step 4: Connect

1. Wait for the workflow to reach **"Keep Session Alive"** step
2. In the **logs**, see the **RustDesk ID** (9 digits)
3. Download the **artifact** `credentials-<your-username>-<run-id>` from the Summary tab
4. Open the file to see both **passwords** (RustDesk and macOS)
5. In **RustDesk**, enter the ID and RustDesk password
6. **Connected!** 🎉

> 🔒 **Security**: Passwords do NOT appear in logs. Only in the private artifact.

---

## 🎮 Parsec (Optional)

**Parsec is pre-installed** on all sessions for optional use. If you prefer Parsec's lower latency:

1. Connect via RustDesk first
2. Open **Parsec** from Applications
3. Log in with your Parsec account
4. When prompted for permissions (Input Monitoring, Screen Recording):
   - **User:** `yourname` (the admin user created by the workflow)
   - **Password:** Use the macOS password from the credentials file
5. Enable hosting in Parsec settings
6. Connect from your other device!

> ℹ️ The workflow creates a dedicated admin user (`yourname`) that appears in Users & Groups and can authenticate in Privacy & Security dialogs.

---

## 📊 Runner Sizes

| Tier | Runner | vCPUs | RAM | Arch | Chip | Plans |
|------|--------|-------|-----|------|------|-------|
| **Standard** | `macos-{version}` | 3 | 7 GB | arm64 | M1 | Free, Pro, Team, Enterprise |
| **Intel** | `macos-26-intel` | 4 | 14 GB | x64 | Intel Xeon | Free, Pro, Team, Enterprise |
| **Large** | `macos-{version}-large` | 12 | 30 GB | arm64 (14/15) / x64 (26) | M1 Pro / Intel | Team, Enterprise |
| **XLarge** | `macos-{version}-xlarge` | 24 (14/15) / 5+8GPU (26) | 70 GB (14/15) / 14 GB (26) | arm64 | M1 Max / M2 | Enterprise |

> ⚠️ **Important:** macOS 26 (Tahoe) has **different hardware** than 14/15:
> - `large` runs on **Intel x64** (not ARM like 14/15)
> - `xlarge` uses **M2** with 8-core GPU (5 vCPU + 14 GB RAM)
> - New `intel` tier available — standard Intel x64 runner
> - The system auto-detects CPU type and downloads the correct binaries

---

## 🍎 macOS Versions

| Version | Codename | Status | Notes |
|---------|----------|--------|-------|
| **14** | Sonoma | ✅ GA | Default, M1 ARM64 |
| **15** | Sequoia | ✅ GA | Newer features |
| **26** | Tahoe | ✅ GA | Latest release, mixed ARM64/Intel (see runner sizes) |

> 💡 **Tip**: Use macOS 14 for maximum stability. macOS 26 offers new `intel` tier and different hardware configs.

### Larger Runners (Large/XLarge)

To use larger runners, your organization needs a **Team** or **Enterprise** GitHub plan.

**How to enable larger runners:**

1. Go to **Settings** → **Actions** → **Runners**
2. Under "Larger runners", configure available runners
3. `macos-14-large` and `macos-14-xlarge` runners will become available

> 💡 **Tip**: Large/XLarge runners are ideal for iOS app compilation, simulators, and heavy tasks.

---

## 🌐 Unique IP Guarantee

Each session can be configured to have a **guaranteed unique IP address**. This is useful for:

- 🔒 Avoiding IP-based rate limits or bans
- 🆕 Ensuring each machine/user gets a fresh IP
- 📊 Tracking which IPs were used by whom

### How It Works

1. **IP Detection**: Every session detects and logs its public IP
2. **IP History**: IPs are tracked per user and stored in cache
3. **Duplicate Warning**: System alerts if an IP was previously used
4. **VPN Rotation**: Enable "Unique IP" to route through Cloudflare WARP for a different IP

### Enable Unique IP

When starting a workflow, set **"Unique IP"** to `true`:

| Option | Description |
|--------|-------------|
| `false` (default) | Uses GitHub's default IP (may repeat) |
| `true` | Routes through Cloudflare WARP VPN for unique IP |

### IP Information in Credentials

The credentials artifact includes:

```
🌐 Network Information:
  Public IP:  203.0.113.42
  Location:   San Francisco, US
  Provider:   AS13335 Cloudflare
  WARP VPN:   true
```

> ⚠️ **Note**: Even with "Unique IP" enabled, Cloudflare WARP IPs come from a shared pool. For truly dedicated IPs, consider using a paid VPN service.

---

## 🖥️ macOS VNC (via Tailscale)

Access a full macOS desktop remotely using **VNC (Screen Sharing) over Tailscale**. No port forwarding or public IP required.

### Prerequisites

1. **Tailscale Account** — Create one at [tailscale.com](https://tailscale.com)
2. **Tailscale Auth Key** — Generate a reusable auth key at [admin/settings/keys](https://login.tailscale.com/admin/settings/keys)
3. **GitHub Secret** — Add the auth key as `TAILSCALE_AUTH_KEY` in your repository secrets
4. **VNC Client** — Built-in on macOS (Screen Sharing), or use RealVNC/TightVNC on Windows/Linux

### Setup Tailscale Secret

```bash
# Using GitHub CLI
gh secret set TAILSCALE_AUTH_KEY --repo your-username/github-mac-remote
```

Or go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

### Start a VNC Session

1. Go to **Actions** → **"🖥️ macOS VNC Session (Tailscale)"**
2. Click **"Run workflow"**
3. Configure:
   - **macOS Version**: 14 (Sonoma), 15 (Sequoia), or 26 (Tahoe)
   - **Runner Size**: Standard, Large, XLarge, or Intel (macOS 26 only)
   - **Duration**: Session time (1-6 hours)
4. Click **"Run workflow"**

### Connect via VNC

1. **Install Tailscale** on your device: [tailscale.com/download](https://tailscale.com/download)
2. **Join the same Tailscale network** (sign in with the same account)
3. Download the **artifact** `vnc-credentials-<your-username>-<run-id>` from the Summary tab
4. Open your VNC client:
   - **macOS**: Finder → Go → Connect to Server → `vnc://<tailscale-ip>:5900`
   - **Windows**: Use RealVNC or TightVNC → `<tailscale-ip>:5900`
   - **Linux**: Use Remmina or `vncviewer` → `<tailscale-ip>:5900`
5. Enter the **Username** and **Password** from the credentials file
6. **Connected!** 🎉

### How It Works

```
1. GitHub Actions starts a macOS runner (Apple Silicon or Intel)
   ↓
2. macOS Screen Sharing (VNC) is enabled via kickstart
   ↓
3. A VNC password is set and an admin user is created
   ↓
4. Tailscale is installed and connects to your tailnet
   ↓
5. VNC is verified accessible on port 5900
   ↓
6. Credentials saved to private artifact
   ↓
7. Connect from any device on the same Tailscale network
```

> 🔒 **Security**: The VNC connection is tunneled through Tailscale's encrypted mesh network. No ports are exposed to the public internet.

> ⚠️ **Note**: On macOS 14+, VNC remote enablement may result in **view-only access** due to system restrictions. For full interactive control, macOS 14 Standard runner is recommended.
---

## ⏱️ Time Limits

| Plan | Minutes/month | Max per session |
|------|---------------|-----------------|
| **Free** | 2,000 min | 6 hours |
| **Pro** | 3,000 min | 6 hours |
| **Team** | 3,000 min | 6 hours |
| **Enterprise** | Custom | 6 hours |

> ⚠️ **Important**: macOS runners consume minutes at a **10x rate** on Free/Pro plans.
> Example: 1 hour of use = 10 minutes consumed from quota.

### Extended Sessions (>6 hours)

Use the **"🔗 Extended Mac Session"** workflow for longer sessions:

1. Set `max_chains` (max 3 = 18 hours total)
2. System automatically starts new session before timeout
3. New credentials are generated for each chain
4. ~30 seconds downtime between chains

---

## 🦀 Why RustDesk?

We tested several remote access options. Only **RustDesk** works reliably on GitHub Actions VMs:

| Method | Status | Reason |
|--------|--------|--------|
| **RustDesk** | ✅ Works | Uses its own screen capture method |
| VNC | ❌ Doesn't work | Screen Sharing blocked on VMs |
| Parsec (auto) | ❌ Doesn't work | Requires GUI permissions unavailable on VMs |
| Parsec (manual) | ✅ Works | Can be configured manually via RustDesk |

### RustDesk Advantages

- ✅ **No tunnel setup** - Uses relay servers automatically
- ✅ **No account needed** - Just ID and password
- ✅ **Cross-platform** - Windows, macOS, Linux, iOS, Android
- ✅ **Low latency** - Optimized for remote control
- ✅ **Open source** - Free with no vendor lock-in
- ✅ **Audio and file transfer** - Advanced features included

---

## 🔐 Security & Privacy

This project was built with **security in mind**, especially for multi-user environments.

### 🛡️ Credential Protection

| Feature | Implementation |
|---------|----------------|
| **Masked Passwords** | Uses `::add-mask::` - passwords NEVER appear in logs |
| **Private Artifact** | Credentials saved in downloadable artifact, not in logs |
| **User Identification** | Artifact named with initiating user: `credentials-<user>-<run-id>` |
| **Dedicated Admin User** | Creates `yourname` admin user for Privacy & Security dialogs |
| **Ephemeral Session** | Everything is destroyed when workflow ends |
| **Unique Credentials** | Each session generates new ID and passwords |

### 🔒 User Isolation

In repositories with multiple collaborators:

- **Each user** can identify their own artifact by name
- **Passwords don't leak** in public workflow logs
- **Sessions are independent** - each run has unique credentials

### 📋 Security Flow

```
1. User starts workflow
   ↓
2. Admin user 'yourname' created with UID >= 501 (visible in GUI)
   ↓
3. macOS password generated for admin user (12 alphanumeric characters)
   ↓
4. RustDesk password generated (12 alphanumeric characters)
   ↓
5. Both passwords masked with ::add-mask:: (won't appear in any log)
   ↓
6. Credentials saved to file inside artifact
   ↓
7. Artifact named: credentials-{user}-{run_id}
   ↓
8. Only those with repository access can download artifacts
```

### ⚠️ Considerations

| Scenario | Security Level |
|----------|----------------|
| **Private Repository** | 🟢 High - Only collaborators see artifacts |
| **Public Repository** | 🟡 Medium - Anyone can download artifacts |
| **Org with multiple members** | 🟢 High - Each downloads only their artifact |

### 📌 Recommendations

1. **Use a private repository** for maximum security
2. **Don't share** the credentials file
3. **Sessions are temporary** - credentials expire when workflow ends
4. **For organizations**: Each member should only download artifacts with their name

---

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── rustdesk-session.yml   # RustDesk Mac session (main)
│       ├── extended-session.yml   # Mac session with chaining
│       └── vnc-session.yml        # macOS VNC session (Tailscale)
├── scripts/
│   ├── setup-rustdesk.sh         # Configures RustDesk
│   ├── install-parsec.sh         # Installs Parsec (optional)
│   ├── keep-alive.sh             # Keeps session active
│   ├── system-info.sh            # System information
│   ├── ip-manager.sh             # IP detection and tracking
│   └── setup-warp.sh             # Cloudflare WARP VPN setup
├── configs/
│   └── hardware-tiers.json       # Hardware configurations
└── README.md
```

---

## ❓ Troubleshooting

### "RustDesk won't connect"

1. Check if the workflow is still on the "Keep Session Alive" step
2. Confirm the ID and password are correct
3. Test your internet connection
4. Wait a few seconds and try again

### "Session ended early"

1. GitHub has a maximum 6h timeout per job
2. Use "Extended Session" for longer sessions
3. Check if keep-alive is generating output in logs

### "Black screen or unresponsive"

1. Wait a few seconds - the VM may be initializing
2. Try moving the mouse or pressing a key
3. If it persists, cancel and start a new session

### "Large/XLarge runners not showing"

1. Check if your organization has a Team or Enterprise plan
2. Configure larger runners in Settings → Actions → Runners
3. Runners need to be enabled for the repository

### "Parsec permissions not working"

1. When the authentication dialog appears, use:
   - **User:** `yourname` (not Anka or runner)
   - **Password:** The macOS password from the credentials file
2. The user `yourname` should appear in Users & Groups as an Admin
3. If the user doesn't appear, the workflow may have failed - check the logs

---

## ⚖️ Responsible Use

This project is for **legitimate development and testing**:

- ✅ Testing iOS/macOS apps
- ✅ Occasional development work
- ✅ CI/CD requiring macOS environment
- ✅ Swift/Xcode project compilation
- ❌ 24/7 usage (use MacStadium for that)
- ❌ Mining or abusive workloads

⚠️ GitHub may suspend accounts that abuse resources.

---

## 🔧 Advanced Configuration

### Credentials Included

Each session provides two sets of credentials in the artifact:

| Credential | Purpose |
|------------|---------|
| **macOS Admin User (`yourname`)** | System authentication (Privacy & Security, app installs) |
| **RustDesk ID + Password** | Remote desktop connection |

> 💡 The admin user `yourname` is created specifically to authenticate in GUI dialogs. It appears in Users & Groups alongside the default Anka user.

### Environment Variables

Workflows use these variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SESSION_DURATION` | Duration in hours | 2 |
| `MACOS_VERSION` | macOS version (14, 15, 26) | 14 |
| `CURRENT_IP` | Public IP address of the session | Auto-detected |
| `IP_CITY` | City location of the IP | Auto-detected |
| `IP_COUNTRY` | Country of the IP | Auto-detected |
| `WARP_ENABLED` | Whether Cloudflare WARP VPN is active | false |
| `IP_IS_DUPLICATE` | Whether this IP was used before | false |
| `RUSTDESK_PASSWORD` | RustDesk password (auto-generated) | Random |
| `MAC_PASSWORD` | macOS user password (auto-generated) | Random |
| `TAILSCALE_IP` | Tailscale IP for VNC connection | Auto-assigned |
| `VNC_PASSWORD` | VNC password (auto-generated) | Random |

### Customization

To customize behavior, edit the workflow at `.github/workflows/rustdesk-session.yml`.

---

## 📄 License

MIT License - Use freely, but at your own risk.

---

## 🙏 Credits

- **GitHub Actions** - Runner infrastructure
- **RustDesk** - Open-source remote desktop software
- **Parsec** - Low-latency game streaming technology
- **Tailscale** - Secure mesh VPN for VNC connections

---

<p align="center">
  <b>Made with ❤️ for the community</b><br>
  <sub>⭐ Star if this project helped you!</sub>
</p>
