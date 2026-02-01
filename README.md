# 🍎 GitHub Mac Remote

> **Acesse Macs com Apple Silicon (M1/M2/M3/M4) remotamente através do GitHub Actions**

Transforme runners do GitHub Actions em Macs acessíveis remotamente. Uma alternativa a serviços como MacStadium, usando a infraestrutura do GitHub.

[![RustDesk Session](https://img.shields.io/badge/🦀_Iniciar_Sessão-RustDesk-orange?style=for-the-badge)](../../actions/workflows/rustdesk-session.yml)

---

## ✨ Recursos

| Recurso | Descrição |
|---------|-----------|
| 🖥️ **Mac ARM64 Real** | Mac Mini virtualizado com Apple Silicon |
| 🦀 **RustDesk** | Acesso remoto sem configuração complexa |
| ⏱️ **Sessões Configuráveis** | De 1h até 6h por sessão |
| 🔗 **Sessões Estendidas** | Encadeamento automático para >6h |
| 📊 **Múltiplos Tamanhos** | Standard, Large, XLarge |

---

## 🚀 Início Rápido

### Passo 1: Fork ou Clone

```bash
# Clone o repositório
git clone https://github.com/SANSI-GROUP/github-mac-remote.git
```

Ou faça um **Fork** para sua conta/organização.

### Passo 2: Instale o RustDesk no seu computador

Baixe em: **https://rustdesk.com/download**

| Sistema | Download |
|---------|----------|
| Windows | [rustdesk-x86_64.exe](https://github.com/rustdesk/rustdesk/releases/latest) |
| macOS Intel | [rustdesk-x86_64.dmg](https://github.com/rustdesk/rustdesk/releases/latest) |
| macOS Apple Silicon | [rustdesk-aarch64.dmg](https://github.com/rustdesk/rustdesk/releases/latest) |
| Linux | [.deb](https://github.com/rustdesk/rustdesk/releases/latest) / [.AppImage](https://github.com/rustdesk/rustdesk/releases/latest) |

### Passo 3: Inicie uma sessão

1. Vá em **Actions** → **"🦀 RustDesk Mac Session"**
2. Clique em **"Run workflow"**
3. Configure:
   - **Duration**: Tempo da sessão (1-6 horas)
   - **Runner size**: Tamanho do Mac (veja tabela abaixo)
4. Clique em **"Run workflow"**

### Passo 4: Conecte

1. Aguarde o workflow chegar no passo **"Keep Session Alive"**
2. Nos **logs**, veja o **RustDesk ID** (9 dígitos)
3. Baixe o **artifact** `credentials-<seu-usuario>-<run-id>` na aba Summary
4. Abra o arquivo para ver a **senha**
5. No **RustDesk**, digite o ID e a senha
6. **Conectado!** 🎉

> 🔒 **Segurança**: A senha NÃO aparece nos logs. Apenas no artifact privado.

---

## 📊 Tamanhos de Runners

| Tier | Runner | vCPUs | RAM | Chip | Planos |
|------|--------|-------|-----|------|--------|
| **Standard** | `macos-14` | 3 | 7 GB | M1 | Free, Pro, Team, Enterprise |
| **Large** | `macos-14-large` | 12 | 30 GB | M1 Pro | Team, Enterprise |
| **XLarge** | `macos-14-xlarge` | 24 | 70 GB | M1 Max | Enterprise |

### Runners Maiores (Large/XLarge)

Para usar runners maiores, sua organização precisa ter um plano **Team** ou **Enterprise** do GitHub.

**Como habilitar runners maiores:**

1. Vá em **Settings** → **Actions** → **Runners**
2. Em "Larger runners", configure os runners disponíveis
3. Runners `macos-14-large` e `macos-14-xlarge` ficarão disponíveis

> 💡 **Dica**: Runners Large/XLarge são ideais para compilação de apps iOS, simuladores, e tarefas pesadas.

---

## ⏱️ Limites de Tempo

| Plano | Minutos/mês | Máximo por sessão |
|-------|-------------|-------------------|
| **Free** | 2.000 min | 6 horas |
| **Pro** | 3.000 min | 6 horas |
| **Team** | 3.000 min | 6 horas |
| **Enterprise** | Custom | 6 horas |

> ⚠️ **Importante**: Runners macOS consomem minutos em taxa de **10x** no plano Free/Pro. 
> Exemplo: 1 hora de uso = 10 minutos consumidos da cota.

### Sessões Estendidas (>6 horas)

Use o workflow **"🔗 Extended Mac Session"** para sessões mais longas:

1. Configure `max_chains` (máx 3 = 18 horas total)
2. O sistema inicia nova sessão automaticamente antes do timeout
3. Novas credenciais são geradas para cada encadeamento
4. ~30 segundos de downtime entre encadeamentos

---

## 🦀 Por que RustDesk?

Testamos várias opções de acesso remoto. Apenas o **RustDesk** funciona de forma confiável em VMs do GitHub Actions:

| Método | Status | Motivo |
|--------|--------|--------|
| **RustDesk** | ✅ Funciona | Usa método próprio de captura de tela |
| VNC | ❌ Não funciona | Screen Sharing bloqueado em VMs |
| Parsec | ❌ Não funciona | Requer permissões GUI não disponíveis em VMs |

### Vantagens do RustDesk

- ✅ **Sem configuração de túnel** - Usa servidores relay automaticamente
- ✅ **Sem conta necessária** - Apenas ID e senha
- ✅ **Multiplataforma** - Windows, macOS, Linux, iOS, Android
- ✅ **Baixa latência** - Otimizado para controle remoto
- ✅ **Open source** - Gratuito e sem vendor lock-in
- ✅ **Áudio e transferência de arquivos** - Recursos avançados incluídos

---

## 📁 Estrutura do Projeto

```
.
├── .github/
│   └── workflows/
│       ├── rustdesk-session.yml   # Sessão RustDesk (principal)
│       └── extended-session.yml   # Sessão com encadeamento
├── scripts/
│   ├── setup-rustdesk.sh         # Configura RustDesk
│   ├── keep-alive.sh             # Mantém sessão ativa
│   └── system-info.sh            # Informações do sistema
├── configs/
│   └── hardware-tiers.json       # Configurações de hardware
└── README.md
```

---

## 🔐 Segurança e Privacidade

Este projeto foi desenvolvido com **segurança em mente**, especialmente para ambientes com múltiplos usuários.

### 🛡️ Proteção de Credenciais

| Recurso | Implementação |
|---------|---------------|
| **Senha Mascarada** | A senha usa `::add-mask::` do GitHub Actions e NUNCA aparece nos logs |
| **Artifact Privado** | Credenciais salvas em artifact baixável, não nos logs |
| **Identificação** | Artifact nomeado com o usuário que iniciou: `credentials-<usuario>-<run-id>` |
| **Sessão Efêmera** | Tudo é destruído quando o workflow termina |
| **ID Único** | Cada sessão gera um novo ID e senha |

### 🔒 Isolamento entre Usuários

Em repositórios com múltiplos colaboradores:

- **Cada usuário** só consegue identificar seu próprio artifact pelo nome
- **Senhas não vazam** nos logs públicos do workflow
- **Sessões são independentes** - cada execução tem credenciais únicas

### 📋 Fluxo de Segurança

```
1. Usuário inicia workflow
   ↓
2. Senha gerada com openssl (12 caracteres alfanuméricos)
   ↓
3. Senha mascarada com ::add-mask:: (não aparece em nenhum log)
   ↓
4. Credenciais salvas em arquivo dentro do artifact
   ↓
5. Artifact nomeado: credentials-{usuario}-{run_id}
   ↓
6. Apenas quem tem acesso ao repositório pode baixar artifacts
```

### ⚠️ Considerações

| Cenário | Nível de Segurança |
|---------|-------------------|
| **Repositório Privado** | 🟢 Alto - Apenas colaboradores veem artifacts |
| **Repositório Público** | 🟡 Médio - Qualquer pessoa pode baixar artifacts |
| **Org com múltiplos membros** | 🟢 Alto - Cada um baixa apenas seu artifact |

### 📌 Recomendações

1. **Use repositório privado** para máxima segurança
2. **Não compartilhe** o arquivo de credenciais
3. **Sessões são temporárias** - credenciais expiram quando o workflow termina
4. **Para organizações**: Cada membro deve baixar apenas artifacts com seu nome

---

## ❓ Troubleshooting

### "RustDesk não conecta"

1. Verifique se o workflow ainda está no passo "Keep Session Alive"
2. Confirme que o ID e senha estão corretos
3. Teste sua conexão de internet
4. Aguarde alguns segundos e tente novamente

### "Sessão terminou antes do esperado"

1. GitHub tem timeout máximo de 6h por job
2. Use "Extended Session" para sessões mais longas
3. Verifique se o keep-alive está gerando output nos logs

### "Tela preta ou sem resposta"

1. Aguarde alguns segundos - a VM pode estar inicializando
2. Tente mover o mouse ou pressionar uma tecla
3. Se persistir, cancele e inicie nova sessão

### "Runners Large/XLarge não aparecem"

1. Verifique se sua organização tem plano Team ou Enterprise
2. Configure os larger runners em Settings → Actions → Runners
3. Os runners precisam estar habilitados para o repositório

---

## ⚖️ Uso Responsável

Este projeto é para **desenvolvimento e testes legítimos**:

- ✅ Testar apps iOS/macOS
- ✅ Desenvolvimento ocasional
- ✅ CI/CD que requer ambiente macOS
- ✅ Compilação de projetos Swift/Xcode
- ❌ Uso 24/7 (use MacStadium para isso)
- ❌ Mining ou workloads abusivos

⚠️ O GitHub pode suspender contas que abusem dos recursos.

---

## 🔧 Configuração Avançada

### Variáveis de Ambiente

Os workflows usam estas variáveis:

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `SESSION_DURATION` | Duração em horas | 2 |
| `RUSTDESK_PASSWORD` | Senha (auto-gerada) | Aleatória |

### Customização

Para customizar o comportamento, edite o workflow em `.github/workflows/rustdesk-session.yml`.

---

## 📄 Licença

MIT License - Use livremente, mas por sua conta e risco.

---

## 🙏 Créditos

- **GitHub Actions** - Infraestrutura de runners
- **RustDesk** - Software de acesso remoto open-source
- **SANSI GROUP** - Manutenção e melhorias

---

<p align="center">
  <b>Desenvolvido pela SANSI GROUP</b><br>
  <sub>⭐ Dê uma estrela se este projeto te ajudou!</sub>
</p>
