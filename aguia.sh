#!/bin/bash

# ==========================================
# Cores para o terminal
# ==========================================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# ==========================================
# Verificação de Root
# ==========================================
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}Erro: Este script precisa ser executado como root!${NC}"
   echo "Digite: sudo su"
   exit 1
fi

# ==========================================
# Instalação Global (Comandos: aguia / aguiaxray)
# ==========================================
SCRIPT_PATH=$(readlink -f "$0")
if [ ! -f "/usr/local/bin/aguia" ]; then
    cp "$SCRIPT_PATH" /usr/local/bin/aguia
    cp "$SCRIPT_PATH" /usr/local/bin/aguiaxray
    chmod +x /usr/local/bin/aguia
    chmod +x /usr/local/bin/aguiaxray
fi

# ==========================================
# Verificação de Key e Dependências
# ==========================================
if [ ! -f "/etc/aguia.key" ]; then
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${GREEN}      PREPARANDO O SISTEMA ÁGUIA FREE       ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo -e "${YELLOW}Atualizando pacotes e instalando dependências...${NC}"
    
    apt-get update -y > /dev/null 2>&1
    apt-get install -y curl wget unzip jq tar procps uuid-runtime > /dev/null 2>&1
    
    echo -e "${GREEN}Dependências instaladas com sucesso!${NC}"
    echo -e "${CYAN}============================================${NC}"
    
    while true; do
        read -p "Digite a Key de instalação do script: " USER_KEY
        if [ "$USER_KEY" == "aguiafree" ]; then
            echo -e "${GREEN}Key validada com sucesso! Acesso permitido.${NC}"
            echo "validado" > /etc/aguia.key
            
            echo -e "${YELLOW}Baixando e instalando o Xray-core (oficial)...${NC}"
            bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
            sleep 2
            break
        else
            echo -e "${RED}Key incorreta! Tente novamente.${NC}"
        fi
    done
fi

# ==========================================
# Funções de Monitoramento
# ==========================================
sys_info() {
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    MEM_PERCENT=$(free -m | awk '/Mem:/ {printf("%.0f"), $3/$2*100}')
    CPU_USAGE=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
}

# ==========================================
# Funções do Xray
# ==========================================
CONFIG_FILE="/usr/local/etc/xray/config.json"

ativar_xray_novo() {
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${GREEN}             ATIVAR XRAY (VLESS)            ${NC}"
    echo -e "${CYAN}============================================${NC}"
    read -p "Digite a porta desejada (Ex: 443 ou 80): " PORTA
    read -p "Digite a CDN/SNI (Ex: seucdn.com) ou [ENTER] para pular: " CDN_HOST

    if [ -z "$CDN_HOST" ]; then
        CDN_HOST="sem_cdn"
    fi

    UUID=$(uuidgen)
    echo -e "\n${YELLOW}Gerando configurações na porta $PORTA...${NC}"

    cat <<EOF > $CONFIG_FILE
{
  "inbounds": [{
    "port": $PORTA,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "level": 0}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/aguia",
        "headers": {
          "Host": "$CDN_HOST"
        }
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

    systemctl restart xray
    systemctl enable xray > /dev/null 2>&1

    echo -e "${GREEN}Xray ativado com sucesso!${NC}"
    echo -e "-----------------------------------"
    echo -e "${CYAN}Porta:${NC} $PORTA"
    echo -e "${CYAN}UUID:${NC} $UUID"
    echo -e "${CYAN}CDN/SNI:${NC} $CDN_HOST"
    echo -e "-----------------------------------"
    read -p "Pressione [ENTER] para voltar ao menu."
}

gerenciar_xray() {
    while true; do
        clear
        PORTA_ATIVA=$(jq -r '.inbounds[0].port' $CONFIG_FILE 2>/dev/null)
        CDN_ATIVO=$(jq -r '.inbounds[0].streamSettings.wsSettings.headers.Host' $CONFIG_FILE 2>/dev/null)
        
        echo -e "${CYAN}============================================${NC}"
        echo -e "${GREEN}            GERENCIAR XRAY ATIVO            ${NC}"
        echo -e "${CYAN}============================================${NC}"
        echo -e " ${YELLOW}STATUS:${NC} ${GREEN}ATIVO${NC}"
        echo -e " ${YELLOW}PORTA:${NC}  $PORTA_ATIVA"
        echo -e " ${YELLOW}CDN:${NC}    $CDN_ATIVO"
        echo -e "${CYAN}============================================${NC}"
        echo -e " ${YELLOW}[01]${NC} - Remover Xray"
        echo -e " ${YELLOW}[02]${NC} - Alterar Porta"
        echo -e " ${YELLOW}[03]${NC} - Trocar CDN"
        echo -e " ${YELLOW}[00]${NC} - Voltar ao Menu Principal"
        echo -e "${CYAN}============================================${NC}"
        read -p "Escolha uma opção: " SUB_OPCAO

        case $SUB_OPCAO in
            01)
                echo -e "\n${RED}Aviso: Isso irá desativar a porta atual do Xray.${NC}"
                read -p "Tem certeza que deseja remover? (s/n): " CONFIRMA
                if [[ "$CONFIRMA" == "s" || "$CONFIRMA" == "S" ]]; then
                    systemctl stop xray
                    rm -f $CONFIG_FILE
                    echo -e "${GREEN}Xray desativado e removido!${NC}"
                    sleep 2
                    break
                fi
                ;;
            02)
                read -p "Digite a nova porta para substituir a $PORTA_ATIVA: " NOVA_PORTA
                if [[ "$NOVA_PORTA" =~ ^[0-9]+$ ]]; then
                    jq '.inbounds[0].port = '"$NOVA_PORTA"'' $CONFIG_FILE > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json $CONFIG_FILE
                    systemctl restart xray
                    echo -e "${GREEN}Porta alterada com sucesso!${NC}"
                    sleep 2
                else
                    echo -e "${RED}Porta inválida!${NC}"
                    sleep 2
                fi
                ;;
            03)
                read -p "Digite o novo domínio CDN: " NOVO_CDN
                if [[ -n "$NOVO_CDN" ]]; then
                    jq '.inbounds[0].streamSettings.wsSettings.headers.Host = "'"$NOVO_CDN"'"' $CONFIG_FILE > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json $CONFIG_FILE
                    systemctl restart xray
                    echo -e "${GREEN}CDN alterado com sucesso!${NC}"
                    sleep 2
                else
                    echo -e "${RED}Nenhuma CDN inserida!${NC}"
                    sleep 2
                fi
                ;;
            00)
                break
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

xray_menu() {
    # Verifica se o arquivo config.json existe e possui a chave 'inbounds'
    if [ -f "$CONFIG_FILE" ] && grep -q '"inbounds"' "$CONFIG_FILE"; then
        gerenciar_xray
    else
        ativar_xray_novo
    fi
}

excluir_script() {
    echo -e "\n${RED}============================================${NC}"
    echo -e "${RED}   ATENÇÃO: DESINSTALAÇÃO TOTAL DO SISTEMA  ${NC}"
    echo -e "${RED}============================================${NC}"
    read -p "Tem certeza que deseja excluir tudo? (s/n): " CONFIRMA_EXCLUSAO
    
    if [[ "$CONFIRMA_EXCLUSAO" == "s" || "$CONFIRMA_EXCLUSAO" == "S" ]]; then
        echo -e "\n${YELLOW}Iniciando desinstalação...${NC}"
        systemctl stop xray > /dev/null 2>&1
        systemctl disable xray > /dev/null 2>&1
        
        # Desinstala o núcleo Xray oficial
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove > /dev/null 2>&1
        
        # Remove atalhos e chaves do script
        rm -f /usr/local/bin/aguia
        rm -f /usr/local/bin/aguiaxray
        rm -f /etc/aguia.key
        
        # Remove o próprio arquivo caso executado diretamente
        SCRIPT_NAME="$(basename "$0")"
        if [ "$SCRIPT_NAME" != "aguia" ] && [ "$SCRIPT_NAME" != "aguiaxray" ]; then
            rm -f "$SCRIPT_PATH"
        fi
        
        echo -e "${GREEN}Sistema Águia Free removido com sucesso!${NC}"
        exit 0
    else
        echo -e "${GREEN}Desinstalação cancelada. Retornando ao menu...${NC}"
        sleep 2
    fi
}

# ==========================================
# Menu Principal
# ==========================================
while true; do
    sys_info
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${GREEN}            SCRIPT ÁGUIA FREE               ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo -e " ${MAGENTA}Memória :${NC} ${MEM_USED}MB / ${MEM_TOTAL}MB"
    echo -e " ${MAGENTA}CPU     :${NC} ${CPU_USAGE}% em uso"
    echo -e " ${MAGENTA}RAM     :${NC} ${MEM_PERCENT}% em uso"
    echo -e "${CYAN}============================================${NC}"
    
    # Verifica dinamicamente o status para alterar o nome da opção 01
    if [ -f "$CONFIG_FILE" ] && grep -q '"inbounds"' "$CONFIG_FILE"; then
        echo -e " ${YELLOW}[01]${NC} - Gerenciar Xray ${GREEN}[ATIVO]${NC}"
    else
        echo -e " ${YELLOW}[01]${NC} - Ativar Xray"
    fi
    
    echo -e " ${YELLOW}[02]${NC} - Excluir Script"
    echo -e " ${YELLOW}[00]${NC} - Sair do Painel"
    echo -e "${CYAN}============================================${NC}"
    read -p "Escolha uma opção: " OPCAO

    case $OPCAO in
        01) xray_menu ;;
        02) excluir_script ;;
        00) clear; echo -e "${GREEN}Saindo... Para voltar digite 'aguia' ou 'aguiaxray'.${NC}"; exit 0 ;;
        *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
    esac
done
