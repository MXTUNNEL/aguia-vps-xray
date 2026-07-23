# 🦅 Águia Free - Gerenciador Xray Profissional

O **Águia Free** é um script shell automatizado para servidores VPS Linux (Ubuntu / Debian) projetado para facilitar a instalação e o gerenciamento do **Xray-core** (VLESS + WebSocket). Ideal para quem precisa de conexões seguras e configuradas para uso com CDN/SNI (Cloudflare).

## ✨ Funcionalidades do Painel

O script conta com um menu interativo e inteligente que oferece:

- 📊 **Monitoramento em Tempo Real:** Exibe o consumo exato de CPU e Memória RAM da sua VPS no topo do painel.
- ⚡ **Instalação Rápida e Silenciosa:** Baixa os pacotes e o núcleo Xray oficial sem poluir a tela.
- 🛡️ **VLESS + WS + CDN:** Configuração gerada automaticamente (com UUID de segurança) no padrão ideal para burlar bloqueios.
- ⚙️ **Gerenciamento Dinâmico (Menu Xray):**
  - **Ativar Xray:** Defina a porta (ex: 80, 443) e o Host/CDN.
  - **Alterar Porta:** Troque a porta ativa em segundos, sem precisar refazer toda a configuração.
  - **Trocar CDN:** Altere o domínio/SNI injetado no Xray facilmente.
  - **Remover Xray:** Desativa e limpa a configuração atual.
- 🗑️ **Desinstalação Completa:** Opção de excluir totalmente o script e o Xray do seu servidor com segurança.
- 🌍 **Comandos Globais:** Acesse o painel de qualquer lugar do terminal digitando apenas uma palavra.

---

## 🔑 Chave de Acesso (Key)

Para evitar acessos não autorizados e garantir a integridade da instalação, o script solicitará uma chave (Key) na primeira execução.

> **Key de Instalação:** `aguiafree`

---

## 🚀 Como Instalar na sua VPS

Certifique-se de estar logado como **root** no seu servidor Ubuntu/Debian. Copie o comando abaixo, cole no terminal da sua VPS e aperte ENTER:

```bash
bash <(curl -sL [https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO/main/aguia.sh](https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO/main/aguia.sh))
