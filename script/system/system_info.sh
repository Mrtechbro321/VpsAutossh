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

show_system_info() {
    clear
    echo "========================================"
    echo "          System Information          "
    echo "========================================"
    echo ""
    echo -e "${blue}Operating System:${nc} $(hostnamectl | grep 'Operating System' | cut -d ':' -f2- | xargs)"
    echo -e "${blue}Kernel:${nc} $(uname -r)"
    echo -e "${blue}Architecture:${nc} $(uname -m)"
    echo -e "${blue}Uptime:${nc} $(uptime -p | cut -d " " -f 2-10)"
    echo -e "${blue}Public IP:${nc} $(curl -s ifconfig.me)"
    echo -e "${blue}Domain:${nc} $(cat "$SCRIPT_DIR/domain" 2>/dev/null || echo "Not Set")"
    echo ""
    echo "--- CPU Information ---"
    lscpu | grep -E 'Model name|Architecture|CPU(s)|CPU MHz' | sed 's/^/  /'
    echo ""
    echo "--- Memory Information ---"
    free -h | grep -E 'Mem|Swap' | sed 's/^/  /'
    echo ""
    echo "--- Disk Usage ---"
    df -h / | grep '/' | awk '{print "  Total: " $2 ", Used: " $3 ", Available: " $4 ", Use%: " $5}'
    echo ""
    echo "--- Network Interfaces ---"
    ip -4 a | grep -E 'inet ' | grep -v '127.0.0.1' | awk '{print "  " $NF ": " $2}'
    echo "========================================"
    gum confirm "Press any key to return to Main Menu..."
    "$SCRIPT_DIR/scripts/menu/main_menu.sh"
}

show_system_info
