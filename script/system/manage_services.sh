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

declare -A SERVICES=(
    ["Xray"]="xray"
    ["Nginx"]="nginx"
    ["Dropbear"]="dropbear"
    ["Stunnel"]="stunnel4"
    ["WS-Proxy"]="ws-proxy"
    ["BadVPN-UDPGW@7200"]="badvpn-udpgw@7200"
    ["BadVPN-UDPGW@7300"]="badvpn-udpgw@7300"
    ["Squid"]="squid"
    ["SSHGuard"]="sshguard"
)

check_status() {
    systemctl is-active --quiet "$1"
}

show_service_status() {
    clear
    echo "========================================"
    echo "          Service Status          "
    echo "========================================"
    for name in "${!SERVICES[@]}"; do
        UNIT=${SERVICES[$name]}
        if check_status "$UNIT"; then
            echo -e "${green}✅ ${name}: Running${nc}"
        else
            echo -e "${red}❌ ${name}: Stopped${nc}"
        fi
    done
    echo "========================================"
    gum confirm "Press any key to continue..."
}

manage_services() {
    show_service_status
    CHOICE=$(gum choose --limit=1 --header "  Manage Service" \
      "1. Start Service" \
      "2. Stop Service" \
      "3. Restart Service" \
      "x. Back to Main Menu")

    if [ "$CHOICE" == "x. Back to Main Menu" ]; then
        "$SCRIPT_DIR/scripts/menu/main_menu.sh"
        return
    fi

    SERVICE_TO_MANAGE=$(gum choose --header "Which service?" "${!SERVICES[@]}")
    if [ -z "$SERVICE_TO_MANAGE" ]; then
        log_info "No service selected."
        gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
        return
    fi
    UNIT=${SERVICES[$SERVICE_TO_MANAGE]}

    case "$CHOICE" in
      "1. Start Service")
        systemctl start "$UNIT" > /dev/null 2>&1
        if [ $? -eq 0 ]; then log_success "${SERVICE_TO_MANAGE} started."; else log_error "Failed to start ${SERVICE_TO_MANAGE}."; fi
        ;;
      "2. Stop Service")
        systemctl stop "$UNIT" > /dev/null 2>&1
        if [ $? -eq 0 ]; then log_success "${SERVICE_TO_MANAGE} stopped."; else log_error "Failed to stop ${SERVICE_TO_MANAGE}."; fi
        ;;
      "3. Restart Service")
        systemctl restart "$UNIT" > /dev/null 2>&1
        if [ $? -eq 0 ]; then log_success "${SERVICE_TO_MANAGE} restarted."; else log_error "Failed to restart ${SERVICE_TO_MANAGE}."; fi
        ;;
    esac
    sleep 2
    manage_services # Show menu again
}

manage_services
