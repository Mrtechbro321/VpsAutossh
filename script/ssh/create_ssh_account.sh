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

create_ssh_user() {
    log_info "Creating new SSH user..."
    USERNAME=$(gum input --placeholder "Enter username")
    if [ -z "$USERNAME" ]; then
        log_error "Username cannot be empty."
        return 1
    fi
    PASSWORD=$(gum input --placeholder "Enter password" --password)
    if [ -z "$PASSWORD" ]; then
        log_error "Password cannot be empty."
        return 1
    fi
    EXPIRY_DAYS=$(gum input --placeholder "Expiry duration (in days)" --value "30")
    
    if ! [[ "$EXPIRY_DAYS" =~ ^[0-9]+$ ]]; then
        log_error "Invalid number of days."
        return 1
    fi
    EXPIRY_DATE=$(date -d "+$EXPIRY_DAYS days" +"%Y-%m-%d")

    useradd -e "$EXPIRY_DATE" -s /bin/false -M "$USERNAME"
    echo -e "$PASSWORD\n$PASSWORD" | passwd "$USERNAME" &>/dev/null

    if [ $? -eq 0 ]; then
        log_success "SSH user ${USERNAME} created successfully."
        log_info "Username: ${USERNAME}"
        log_info "Password: ${PASSWORD}"
        log_info "Expiry: ${EXPIRY_DATE}"
        log_info "Ports: SSH (22), Dropbear (109, 143), Stunnel (444, 445, 446), WS (8888), Squid (8080), UDPGW (7200, 7300)"
    else
        log_error "Failed to create SSH user."
    fi
}

create_ssh_user
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
