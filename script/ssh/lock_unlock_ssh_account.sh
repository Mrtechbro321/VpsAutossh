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

lock_unlock_ssh_user() {
    log_info "Locking/unlocking SSH user..."
    USERS=$(awk -F: 
    if [ -z "$USERS" ]; then
        log_warning "No SSH users found."
        return 1
    fi

    USERNAME=$(echo "$USERS" | gum choose --header "Select user to lock/unlock")

    if [ -z "$USERNAME" ]; then
        log_info "No user selected."
        return 0
    fi

    STATUS=$(passwd -S "$USERNAME" | awk 

    if [ "$STATUS" == "L" ]; then
        if gum confirm "Are you sure you want to unlock ${USERNAME}?"; then
            passwd -u "$USERNAME" &>/dev/null
            if [ $? -eq 0 ]; then
                log_success "SSH user ${USERNAME} unlocked successfully."
            else
                log_error "Failed to unlock SSH user ${USERNAME}."
            fi
        else
            log_info "Unlock cancelled."
        fi
    else
        if gum confirm "Are you sure you want to lock ${USERNAME}?"; then
            passwd -l "$USERNAME" &>/dev/null
            if [ $? -eq 0 ]; then
                log_success "SSH user ${USERNAME} locked successfully."
            else
                log_error "Failed to lock SSH user ${USERNAME}."
            fi
        else
            log_info "Lock cancelled."
        fi
    fi
}

lock_unlock_ssh_user
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
