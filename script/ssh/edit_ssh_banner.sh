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
BANNER_FILE="$SCRIPT_DIR/config/banner.conf"

edit_ssh_banner() {
    log_info "Editing SSH banner..."
    nano "$BANNER_FILE"
    if [ $? -eq 0 ]; then
        log_success "SSH banner edited successfully."
        systemctl restart dropbear > /dev/null 2>&1
        log_info "Dropbear service restarted."
    else
        log_error "Failed to edit SSH banner."
    fi
}

edit_ssh_banner
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
