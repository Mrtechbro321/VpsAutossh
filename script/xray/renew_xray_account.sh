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

renew_xray_user() {
    log_info "Renewing Xray user..."
    if [ ! -f "$XRAY_USERS_DB" ] || [ "$(jq 'length' "$XRAY_USERS_DB")" -eq 0 ]; then
        log_warning "No Xray users found."
        return 1
    fi

    USERS=$(jq -r '.[] | .username' "$XRAY_USERS_DB")
    if [ -z "$USERS" ]; then
        log_warning "No Xray users found."
        return 1
    fi

    USERNAME=$(echo "$USERS" | gum choose --header "Select user to renew")

    if [ -z "$USERNAME" ]; then
        log_info "No user selected."
        return 0
    fi

    RENEW_DAYS=$(gum input --placeholder "Enter number of days to renew" --value "30")
    if ! [[ "$RENEW_DAYS" =~ ^[0-9]+$ ]]; then
        log_error "Invalid number of days."
        return 1
    fi

    CURRENT_EXPIRY=$(jq -r ".[] | select(.username == \"$USERNAME\") | .expiry_date" "$XRAY_USERS_DB")
    NEW_EXPIRY_DATE=$(date -d "@$CURRENT_EXPIRY +$RENEW_DAYS days" +%s)

    jq "(.[] | select(.username == \"$USERNAME\") | .expiry_date) = \"$NEW_EXPIRY_DATE\"" "$XRAY_USERS_DB" > "${XRAY_USERS_DB}.tmp" && mv "${XRAY_USERS_DB}.tmp" "$XRAY_USERS_DB"

    if [ $? -eq 0 ]; then
        log_success "Xray user ${USERNAME} renewed successfully until $(date -d @$NEW_EXPIRY_DATE +'%Y-%m-%d')."
    else
        log_error "Failed to renew Xray user ${USERNAME}."
    fi
}

renew_xray_user
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
