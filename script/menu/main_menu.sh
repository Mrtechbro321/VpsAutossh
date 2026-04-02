#!/bin/bash

SCRIPT_DIR="/etc/vpsautossh"

# Source colors and common functions (if any)
source "$SCRIPT_DIR/script/common.sh" 2>/dev/null

# Check for root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${red}=========================================${nc}"
        echo -e "${red}🚫 ERROR: Please run this script as root.${nc}"
        echo -e "${red}=========================================${nc}"
        exit 1
    fi
}

# Get system information
get_system_info() {
    OS_NAME=$(hostnamectl | grep 'Operating System' | cut -d ':' -f2- | xargs)
    UPTIME=$(uptime -p | cut -d " " -f 2-10)
    PUBLIC_IP=$(curl -s ifconfig.me)
    VPS_DOMAIN=$(cat "$SCRIPT_DIR/domain" 2>/dev/null || echo "Not Set")
    USED_RAM=$(free -m | awk 'NR==2 {print $3}')
    TOTAL_RAM=$(free -m | awk 'NR==2 {print $2}')
}

# Display main menu
show_main_menu() {
    clear
    get_system_info

    echo -e "${green}===================================================${nc}"
    echo -e "${green}🚀 VpsAutossh - My VPS Manager${nc}"
    echo -e "${green}===================================================${nc}"
    echo -e "${blue}OS         : ${nc}${OS_NAME}"
    echo -e "${blue}Uptime     : ${nc}${UPTIME}"
    echo -e "${blue}Public IP  : ${nc}${PUBLIC_IP}"
    echo -e "${blue}Domain     : ${nc}${VPS_DOMAIN}"
    echo -e "${green}---------------------------------------------------${nc}"
    echo -e "${blue}Used RAM   : ${nc}${USED_RAM} MB"
    echo -e "${blue}Total RAM  : ${nc}${TOTAL_RAM} MB"
    echo -e "${green}===================================================${nc}"

    local options=(
        "Manage SSH Accounts"
        "Manage Xray Accounts"
        "Manage Services"
        "View System Information"
        "Change Domain"
        "Uninstall Script"
        "Exit"
    )

    local choice
    if command -v gum &> /dev/null; then
        choice=$(gum choose "${options[@]}" --header "MAIN MENU")
    else
        echo -e "${yellow}             MAIN MENU${nc}"
        echo -e "${green}===================================================${nc}"
        for i in "${!options[@]}"; do
            echo -e "${yellow}$((i+1)). ${options[$i]}${nc}"
        done
        echo -e "${yellow}x. Exit${nc}"
        echo -e "${green}===================================================${nc}"
        read -p "Enter your choice: " raw_choice
        case "$raw_choice" in
            1) choice="Manage SSH Accounts" ;;
            2) choice="Manage Xray Accounts" ;;
            3) choice="Manage Services" ;;
            4) choice="View System Information" ;;
            5) choice="Change Domain" ;;
            6) choice="Uninstall Script" ;;
            x|X) choice="Exit" ;;
            *) choice="Invalid" ;;
        esac
    fi

    clear
    case "$choice" in
        "Manage SSH Accounts") "$SCRIPT_DIR/script/menu/ssh_menu.sh" ;;
        "Manage Xray Accounts") "$SCRIPT_DIR/script/menu/xray_menu.sh" ;;
        "Manage Services") "$SCRIPT_DIR/script/system/manage_services.sh" ;;
        "View System Information") "$SCRIPT_DIR/script/system/system_info.sh" ;;
        "Change Domain") "$SCRIPT_DIR/script/system/change_domain.sh" ;;
        "Uninstall Script") 
            read -p "Are you sure you want to uninstall the script? This action cannot be undone. (y/N): " CONFIRM_UNINSTALL
            if [[ "$CONFIRM_UNINSTALL" =~ ^[Yy]$ ]]; then
                "$SCRIPT_DIR/uninstall.sh"
            else
                log_info "Uninstallation cancelled."
                show_main_menu
            fi ;;
        "Exit") exit ;;
        *)
            echo -e "${red}Invalid option. Please try again.${nc}"
            sleep 2
            show_main_menu ;;
    esac
}

check_root
show_main_menu
