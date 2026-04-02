#!/bin/bash

green="\033[0;32m"
red="\033[0;31m"
blue="\033[0;34m"
yellow="\033[1;33m"
nc="\033[0m"

log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }

SCRIPT_DIR="/etc/vpsautossh"
XRAY_CONFIG_PATH="/usr/local/etc/xray/config.json"
XRAY_API_PORT=8010
XRAY_API_ADDRESS="127.0.0.1"
XRAY_USERS_DB="$SCRIPT_DIR/xray_users.db"

# Ensure the database file exists
if [ ! -f "$XRAY_USERS_DB" ]; then
    echo "[]" > "$XRAY_USERS_DB"
fi

create_xray_user() {
    log_info "Creating new Xray user..."
    USERNAME=$(gum input --placeholder "Enter username")
    if [ -z "$USERNAME" ]; then
        log_error "Username cannot be empty."
        return 1
    fi

    UUID=$(gum input --placeholder "UUID (leave empty to auto-generate)" --value "$(cat /proc/sys/kernel/random/uuid)")
    PROTOCOL=$(gum choose --header "Select protocol" "vless" "vmess" "trojan")
    EXPIRY_DAYS=$(gum input --placeholder "Expiry duration (in days)" --value "30")
    
    if ! [[ "$EXPIRY_DAYS" =~ ^[0-9]+$ ]]; then
        log_error "Invalid number of days."
        return 1
    fi
    EXPIRY_DATE=$(date -d "+$EXPIRY_DAYS days" +%s) # Unix timestamp

    local INBOUND_TAG
    local CLIENT_CONFIG
    local XRAY_PORT

    case "$PROTOCOL" in
        vless)
            INBOUND_TAG="vless-in"
            XRAY_PORT=10000
            # Add user via Xray API
            curl -s -X POST \
                -H "Content-Type: application/json" \
                "http://${XRAY_API_ADDRESS}:${XRAY_API_PORT}/traffic" \
                -d "{\"command\": \"addInboundUser\", \"tag\": \"${INBOUND_TAG}\", \"user\": {\"email\": \"${USERNAME}\", \"uuid\": \"${UUID}\", \"level\": 0, \"flow\": \"xtls-rprx-vision\"}}" > /dev/null
            
            DOMAIN=$(cat "$SCRIPT_DIR/domain")
            CLIENT_CONFIG="vless://${UUID}@${DOMAIN}:443?encryption=none&security=tls&type=ws&host=${DOMAIN}&path=/vless#${USERNAME}"
            ;;
        vmess)
            INBOUND_TAG="vmess-in"
            XRAY_PORT=10001
            # Add user via Xray API
            curl -s -X POST \
                -H "Content-Type: application/json" \
                "http://${XRAY_API_ADDRESS}:${XRAY_API_PORT}/traffic" \
                -d "{\"command\": \"addInboundUser\", \"tag\": \"${INBOUND_TAG}\", \"user\": {\"email\": \"${USERNAME}\", \"id\": \"${UUID}\", \"level\": 0}}" > /dev/null
            
            DOMAIN=$(cat "$SCRIPT_DIR/domain")
            CLIENT_CONFIG="vmess://$(echo -n '{\"add\":\"'${DOMAIN}'\",\"aid\":0,\"host\":\"'${DOMAIN}'\",\"id\":\"'${UUID}'\",\"net\":\"ws\",\"path\":\"/vmess\",\"port\":\"443\",\"ps\":\"'${USERNAME}'\",\"scy\":\"auto\",\"sni\":\"'${DOMAIN}'\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}' | base64 -w 0)"
            ;;
        trojan)
            INBOUND_TAG="trojan-in"
            XRAY_PORT=10002
            # Add user via Xray API
            curl -s -X POST \
                -H "Content-Type: application/json" \
                "http://${XRAY_API_ADDRESS}:${XRAY_API_PORT}/traffic" \
                -d "{\"command\": \"addInboundUser\", \"tag\": \"${INBOUND_TAG}\", \"user\": {\"email\": \"${USERNAME}\", \"password\": \"${UUID}\", \"level\": 0}}" > /dev/null
            
            DOMAIN=$(cat "$SCRIPT_DIR/domain")
            CLIENT_CONFIG="trojan://${UUID}@${DOMAIN}:443?security=tls&type=ws&host=${DOMAIN}&path=/trojan#${USERNAME}"
            ;;
        *)
            log_error "Invalid protocol."
            return 1
            ;;
    esac
    
    # Save user info to JSON database
    jq ". += [{\"username\": \"${USERNAME}\", \"uuid\": \"${UUID}\", \"protocol\": \"${PROTOCOL}\", \"expiry_date\": \"${EXPIRY_DATE}\", \"config_link\": \"${CLIENT_CONFIG}\"}]" "$XRAY_USERS_DB" > "${XRAY_USERS_DB}.tmp" && mv "${XRAY_USERS_DB}.tmp" "$XRAY_USERS_DB"

    log_success "Xray user ${USERNAME} (${PROTOCOL}) created successfully."
    log_info "Client Config Link: ${CLIENT_CONFIG}"
}

create_xray_user
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
