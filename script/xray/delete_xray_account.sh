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
XRAY_API_PORT=8010
XRAY_API_ADDRESS="127.0.0.1"
XRAY_USERS_DB="$SCRIPT_DIR/xray_users.db"

delete_xray_user() {
    log_info "Deleting Xray user..."
    if [ ! -f "$XRAY_USERS_DB" ] || [ "$(jq 'length' "$XRAY_USERS_DB")" -eq 0 ]; then
        log_warning "No Xray users found."
        return 1
    fi

    USERS=$(jq -r '.[] | .username' "$XRAY_USERS_DB")
    if [ -z "$USERS" ]; then
        log_warning "No Xray users found."
        return 1
    fi

    USERNAME=$(echo "$USERS" | gum choose --header "Select user to delete")

    if [ -z "$USERNAME" ]; then
        log_info "No user selected."
        return 0
    fi

    USER_DATA=$(jq -r ".[] | select(.username == \"$USERNAME\")" "$XRAY_USERS_DB")
    UUID=$(echo "$USER_DATA" | jq -r ".uuid")
    PROTOCOL=$(echo "$USER_DATA" | jq -r ".protocol")
    INBOUND_TAG="${PROTOCOL}-in"

    if gum confirm "Are you sure you want to delete ${USERNAME} (${PROTOCOL})?"; then
        # Remove user via Xray API
        if [ "$PROTOCOL" == "trojan" ]; then
            curl -s -X POST \
                -H "Content-Type: application/json" \
                "http://${XRAY_API_ADDRESS}:${XRAY_API_PORT}/traffic" \
                -d "{\"command\": \"removeInboundUser\", \"tag\": \"${INBOUND_TAG}\", \"email\": \"${USERNAME}\"}" > /dev/null
        else
            curl -s -X POST \
                -H "Content-Type: application/json" \
                "http://${XRAY_API_ADDRESS}:${XRAY_API_PORT}/traffic" \
                -d "{\"command\": \"removeInboundUser\", \"tag\": \"${INBOUND_TAG}\", \"email\": \"${USERNAME}\"}" > /dev/null
        fi

        # Remove from JSON database
        jq "del(.[] | select(.username == \"$USERNAME\"))" "$XRAY_USERS_DB" > "${XRAY_USERS_DB}.tmp" && mv "${XRAY_USERS_DB}.tmp" "$XRAY_USERS_DB"

        log_success "Xray user ${USERNAME} deleted successfully."
    else
        log_info "Deletion cancelled."
    fi
}

delete_xray_user
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
