# 🍎 GitHub Mac Remote

> **Transforme runners GitHub Actions em Mac Minis remotos acessíveis**

Acesse Mac Minis com Apple Silicon (M1/M2/M3) através do GitHub Actions. Similar ao MacStadium, mas usando a infraestrutura do GitHub.

[![Start Mac Session](https://img.shields.io/badge/▶️_Start_Mac_Session-blue?style=for-the-badge)](../../actions/workflows/mac-session.yml)
[![Extended Session](https://img.shields.io/badge/🔗_Extended_Session-green?style=for-the-badge)](../../actions/workflows/extended-session.yml)
[![Parsec Session](https://img.shields.io/badge/🎮_Parsec_Session-purple?style=for-the-badge)](../../actions/workflows/parsec-session.yml)

---

## ✨ Features

- 🖥️ **Mac ARM64 Real** - Não é VM, é Mac Mini físico com Apple Silicon
- 🌐 **Acesso Remoto** - Via VNC (nativo) ou Parsec
- ⏱️ **Sessões Configuráveis** - De 1h até 6h (ou mais com chains)
- 🔗 **Sessões Estendidas** - Chain automático para sessões >6h
- 🔐 **Sem Contas Extras** - VNC funciona com IP + senha
- 📊 **Múltiplos Tiers** - Standard, Large, XLarge

---

## 🚀 Quick Start

### 1. Usar este repositório

**Opção A: Fork** (recomendado)
```
Fork este repositório para sua conta
```

**Opção B: Template**
```
Use como template para criar novo repositório
```

### 2. Iniciar uma sessão

1. Vá para **Actions** → **"🍎 Start Mac Session"**
2. Clique em **"Run workflow"**
3. Configure:
   - **Duration**: Tempo da sessão (1-6 horas)
   - **Runner size**: Tamanho do Mac (veja tabela abaixo)
   - **Tunnel type**: cloudflared (recomendado) ou ngrok
4. Clique em **"Run workflow"**

### 3. Conectar

Quando o workflow iniciar, você verá no log:

```
╔══════════════════════════════════════════════════════════════════╗
║              🍎 GITHUB MAC REMOTE - READY TO CONNECT             ║
╚══════════════════════════════════════════════════════════════════╝

🖥️  VNC Credentials:
   ├─ User: runner
   └─ Password: xK7mP9nQ2wLs

🌐 Tunnel URL: https://example-tunnel.trycloudflare.com
```

#### Conectar com Cloudflared:

1. **Instale cloudflared** no seu computador:
   - macOS: `brew install cloudflared`
   - Windows: [Download](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)
   - Linux: `sudo apt install cloudflared`

2. **Crie o túnel local**:
   ```bash
   cloudflared access tcp --hostname <tunnel-url> --url localhost:5900
   ```

3. **Conecte seu cliente VNC** a `localhost:5900`
   - macOS: `open vnc://localhost:5900`
   - Windows: Use RealVNC, TightVNC, ou outro cliente
   - Linux: Use Remmina ou vinagre

4. **Digite a senha** exibida no log

---

## 📊 Hardware Tiers

| Tier | Runner | vCPUs | RAM | Chip | Planos |
|------|--------|-------|-----|------|--------|
| **Standard** | `macos-14` | 3 | 7 GB | M1 | Free, Pro, Team, Enterprise |
| **Large** | `macos-14-large` | 12 | 30 GB | M1 Pro | Team, Enterprise |
| **XLarge** | `macos-14-xlarge` | 24 | 70 GB | M1 Max | Enterprise |

> ⚠️ Runners Large e XLarge requerem planos pagos do GitHub

---

## ⏱️ Limites de Tempo

| Plano | Minutos/mês | Max por sessão |
|-------|-------------|----------------|
| **Free** | 2.000 min | 6 horas |
| **Pro** | 3.000 min | 6 horas |
| **Team** | 3.000 min | 6 horas |
| **Enterprise** | Customizado | 6 horas |

### Sessões Estendidas (>6 horas)

Use o workflow **"🔗 Extended Mac Session"** para sessões mais longas:

1. Configure `max_chains` (máximo 3 = 18 horas)
2. O sistema dispara automaticamente nova sessão antes do timeout
3. Novas credenciais são geradas para cada chain
4. ~30 segundos de downtime entre chains

---

## 🎮 Parsec (Opcional)

Para melhor performance gráfica, use o Parsec:

### Configurar Parsec

1. **Obtenha seu Session ID**:
   ```bash
   curl -X POST https://kessel-api.parsecgaming.com/v1/auth \
     -H 'Content-Type: application/json' \
     -d '{"email":"seu@email.com","password":"suasenha","tfa":"123456"}'
   ```
   
   > Nota: Se você tem 2FA, inclua o código no campo `tfa`

2. **Adicione aos Secrets**:
   - Vá em **Settings** → **Secrets** → **Actions**
   - Adicione: `PARSEC_SESSION_ID` = seu session_id

3. **Use o workflow Parsec**:
   - **Actions** → **"🎮 Parsec Mac Session"**

### Vantagens do Parsec

- ✅ Melhor qualidade de vídeo
- ✅ Menor latência
- ✅ Suporte a gamepad
- ❌ Requer conta Parsec
- ❌ Configuração mais complexa

---

## 📁 Estrutura do Projeto

```
.
├── .github/
│   └── workflows/
│       ├── mac-session.yml        # Sessão simples
│       ├── extended-session.yml   # Sessão com chain
│       └── parsec-session.yml     # Sessão com Parsec
├── scripts/
│   ├── setup-vnc.sh              # Configura Screen Sharing
│   ├── setup-tunnel.sh           # Inicia túnel
│   ├── setup-parsec.sh           # Configura Parsec
│   ├── keep-alive.sh             # Mantém sessão ativa
│   ├── show-credentials.sh       # Exibe credenciais
│   └── system-info.sh            # Info do sistema
├── configs/
│   └── hardware-tiers.json       # Configurações de hardware
└── README.md
```

---

## 🔧 Configuração Avançada

### Secrets Disponíveis

| Secret | Descrição | Obrigatório |
|--------|-----------|-------------|
| `PARSEC_SESSION_ID` | Session ID do Parsec | Apenas para Parsec |
| `NGROK_AUTH_TOKEN` | Token do ngrok (aumenta limites) | Não |

### Variáveis de Ambiente

Os workflows usam estas variáveis (configuráveis via inputs):

- `SESSION_DURATION`: Duração em horas
- `TUNNEL_TYPE`: `cloudflared` ou `ngrok`
- `VNC_PASSWORD`: Gerada automaticamente

---

## ❓ Troubleshooting

### "Não consigo conectar ao VNC"

1. Verifique se o cloudflared está rodando localmente
2. Confirme que está usando a URL correta do túnel
3. Tente `localhost:5900` no cliente VNC

### "Túnel não inicia"

1. Verifique os logs do workflow
2. Tente usar ngrok como alternativa
3. Para ngrok, configure `NGROK_AUTH_TOKEN`

### "Parsec não aparece na lista"

1. Confirme que o `PARSEC_SESSION_ID` está correto
2. Verifique se está logado na mesma conta
3. Aguarde alguns segundos e atualize

### "Sessão terminou antes do tempo"

1. GitHub tem timeout de 6h máximo
2. Use "Extended Session" para sessões maiores
3. Verifique se há output sendo gerado (keep-alive)

---

## ⚖️ Uso Responsável

Este projeto é para **desenvolvimento e testes legítimos**:

- ✅ Testar apps iOS/macOS
- ✅ Desenvolvimento ocasional
- ✅ CI/CD que requer ambiente macOS
- ❌ Uso 24/7 (use MacStadium para isso)
- ❌ Mineração ou workloads abusivos

O GitHub pode suspender contas que abusam dos recursos.

---

## 📄 Licença

MIT License - Use livremente, mas por sua conta e risco.

---

## 🙏 Créditos

- **GitHub Actions** - Infraestrutura
- **Cloudflare** - Túneis gratuitos via cloudflared
- **Parsec** - Streaming de alta performance

---

<p align="center">
  <b>Feito com ❤️ para a comunidade</b><br>
  <sub>Star ⭐ se este projeto te ajudou!</sub>
</p>
