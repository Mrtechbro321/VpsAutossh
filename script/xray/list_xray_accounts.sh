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

list_xray_users() {
    log_info "Listing all Xray users..."
    if [ ! -f "$XRAY_USERS_DB" ] || [ "$(jq 'length' "$XRAY_USERS_DB")" -eq 0 ]; then
        log_warning "No Xray users found."
        return 1
    fi

    echo ""
    echo "===================================================================================================="
    printf "%-20s %-40s %-10s %-15s\n" "Username" "UUID" "Protocol" "Expiry Date"
    echo "===================================================================================================="
    jq -r '.[] | format("%-20s %-40s %-10s %-15s", .username, .uuid, .protocol, (.expiry_date | tonumber | strftime("%Y-%m-%d")))' "$XRAY_USERS_DB"
    echo "===================================================================================================="
}

list_xray_users
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
