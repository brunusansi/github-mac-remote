# 🍎 GitHub Mac Remote

> **Access Apple Silicon Macs (M1/M2/M3/M4) remotely through GitHub Actions**

Turn GitHub Actions runners into remotely accessible Macs. An alternative to services like MacStadium, using GitHub's infrastructure.

[![RustDesk Session](https://img.shields.io/badge/🦀_Start_Session-RustDesk-orange?style=for-the-badge)](../../actions/workflows/rustdesk-session.yml)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Real Mac ARM64** | Virtualized Mac Mini with Apple Silicon |
| 🦀 **RustDesk** | Remote access without complex setup |
| 🎮 **Parsec Pre-installed** | Optional low-latency alternative |
| ⏱️ **Configurable Sessions** | From 1h to 6h per session |
| 🔗 **Extended Sessions** | Auto-chaining for >6h sessions |
| 📊 **Multiple Sizes** | Standard, Large, XLarge |
| 🔒 **Secure Credentials** | Password never shown in logs |

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
   - **Runner size**: Mac size (see table below)
4. Click **"Run workflow"**

### Step 4: Connect

1. Wait for the workflow to reach **"Keep Session Alive"** step
2. In the **logs**, see the **RustDesk ID** (9 digits)
3. Download the **artifact** `credentials-<your-username>-<run-id>` from the Summary tab
4. Open the file to see the **password**
5. In **RustDesk**, enter the ID and password
6. **Connected!** 🎉

> 🔒 **Security**: The password does NOT appear in logs. Only in the private artifact.

---

## 🎮 Parsec (Optional)

**Parsec is pre-installed** on all sessions for optional use. If you prefer Parsec's lower latency:

1. Connect via RustDesk first
2. Open **Parsec** from Applications
3. Log in with your Parsec account
4. Enable hosting in Parsec settings
5. Connect from your other device!

> ℹ️ Parsec cannot be auto-configured due to macOS VM security restrictions, but it works great when set up manually.

---

## 📊 Runner Sizes

| Tier | Runner | vCPUs | RAM | Chip | Plans |
|------|--------|-------|-----|------|-------|
| **Standard** | `macos-14` | 3 | 7 GB | M1 | Free, Pro, Team, Enterprise |
| **Large** | `macos-14-large` | 12 | 30 GB | M1 Pro | Team, Enterprise |
| **XLarge** | `macos-14-xlarge` | 24 | 70 GB | M1 Max | Enterprise |

### Larger Runners (Large/XLarge)

To use larger runners, your organization needs a **Team** or **Enterprise** GitHub plan.

**How to enable larger runners:**

1. Go to **Settings** → **Actions** → **Runners**
2. Under "Larger runners", configure available runners
3. `macos-14-large` and `macos-14-xlarge` runners will become available

> 💡 **Tip**: Large/XLarge runners are ideal for iOS app compilation, simulators, and heavy tasks.

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
| **Masked Password** | Uses `::add-mask::` - password NEVER appears in logs |
| **Private Artifact** | Credentials saved in downloadable artifact, not in logs |
| **User Identification** | Artifact named with initiating user: `credentials-<user>-<run-id>` |
| **Ephemeral Session** | Everything is destroyed when workflow ends |
| **Unique ID** | Each session generates a new ID and password |

### 🔒 User Isolation

In repositories with multiple collaborators:

- **Each user** can identify their own artifact by name
- **Passwords don't leak** in public workflow logs
- **Sessions are independent** - each run has unique credentials

### 📋 Security Flow

```
1. User starts workflow
   ↓
2. Password generated with openssl (12 alphanumeric characters)
   ↓
3. Password masked with ::add-mask:: (won't appear in any log)
   ↓
4. Credentials saved to file inside artifact
   ↓
5. Artifact named: credentials-{user}-{run_id}
   ↓
6. Only those with repository access can download artifacts
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
│       ├── rustdesk-session.yml   # RustDesk session (main)
│       └── extended-session.yml   # Session with chaining
├── scripts/
│   ├── setup-rustdesk.sh         # Configures RustDesk
│   ├── install-parsec.sh         # Installs Parsec (optional)
│   ├── keep-alive.sh             # Keeps session active
│   └── system-info.sh            # System information
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

### Environment Variables

Workflows use these variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SESSION_DURATION` | Duration in hours | 2 |
| `RUSTDESK_PASSWORD` | Password (auto-generated) | Random |

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

---

<p align="center">
  <b>Made with ❤️ for the community</b><br>
  <sub>⭐ Star if this project helped you!</sub>
</p>
