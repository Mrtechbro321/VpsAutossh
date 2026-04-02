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

renew_ssh_user() {
    log_info "Renewing SSH user..."
    USERS=$(awk -F: 
    if [ -z "$USERS" ]; then
        log_warning "No SSH users found."
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

    CURRENT_EXPIRY=$(chage -l "$USERNAME" | grep 'Account expires' | awk -F': ' '{print $2}')
    if [ "$CURRENT_EXPIRY" == "never" ]; then
        NEW_EXPIRY_DATE=$(date -d "+$RENEW_DAYS days" +"%Y-%m-%d")
    else
        NEW_EXPIRY_DATE=$(date -d "$CURRENT_EXPIRY +$RENEW_DAYS days" +"%Y-%m-%d")
    fi

    chage -E "$NEW_EXPIRY_DATE" "$USERNAME" &>/dev/null
    if [ $? -eq 0 ]; then
        log_success "SSH user ${USERNAME} renewed successfully until ${NEW_EXPIRY_DATE}."
    else
        log_error "Failed to renew SSH user ${USERNAME}."
    fi
}

renew_ssh_user
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
