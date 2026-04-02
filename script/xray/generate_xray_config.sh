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
XRAY_USERS_DB="$SCRIPT_DIR/xray_users.db"

generate_xray_client_config() {
    log_info "Generating Xray client config..."
    if [ ! -f "$XRAY_USERS_DB" ] || [ "$(jq 'length' "$XRAY_USERS_DB")" -eq 0 ]; then
        log_warning "No Xray users found."
        return 1
    fi

    USERS=$(jq -r '.[] | .username' "$XRAY_USERS_DB")
    if [ -z "$USERS" ]; then
        log_warning "No Xray users found."
        return 1
    fi

    USERNAME=$(echo "$USERS" | gum choose --header "Select user to generate config for")

    if [ -z "$USERNAME" ]; then
        log_info "No user selected."
        return 0
    fi

    CLIENT_CONFIG=$(jq -r ".[] | select(.username == \"$USERNAME\") | .config_link" "$XRAY_USERS_DB")

    if [ -n "$CLIENT_CONFIG" ]; then
        log_success "Client config for ${USERNAME}:"
        echo "${CLIENT_CONFIG}"
        echo ""
        log_info "This link can be imported into your Xray client."
    else
        log_error "Config link not found for ${USERNAME}."
    fi
}

generate_xray_client_config
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
