#!/bin/bash

SCRIPT_DIR="/etc/vpsautossh"

# Source colors and common functions
source "$SCRIPT_DIR/script/common.sh" 2>/dev/null

# Display System menu
show_system_menu() {
    clear
    echo -e "${green}===================================================${nc}"
    echo -e "${yellow}             SYSTEM MANAGEMENT${nc}"
    echo -e "${green}===================================================${nc}"

    local options=(
        "Manage Services"
        "View System Information"
        "Change Domain"
        "Back to Main Menu"
    )

    local choice
    if command -v gum &> /dev/null; then
        choice=$(gum choose "${options[@]}" --header "SYSTEM MENU")
    else
        echo -e "${yellow}             SYSTEM MENU${nc}"
        echo -e "${green}===================================================${nc}"
        for i in "${!options[@]}"; do
            echo -e "${yellow}$((i+1)). ${options[$i]}${nc}"
        done
        echo -e "${green}===================================================${nc}"
        read -p "Enter your choice: " raw_choice
        case "$raw_choice" in
            1) choice="Manage Services" ;;
            2) choice="View System Information" ;;
            3) choice="Change Domain" ;;
            4) choice="Back to Main Menu" ;;
            *) choice="Invalid" ;;
        esac
    fi

    clear
    case "$choice" in
        "Manage Services") "$SCRIPT_DIR/script/system/manage_services.sh" ;;
        "View System Information") "$SCRIPT_DIR/script/system/system_info.sh" ;;
        "Change Domain") "$SCRIPT_DIR/script/system/change_domain.sh" ;;
        "Back to Main Menu") "$SCRIPT_DIR/script/menu/main_menu.sh" ;;
        *)
            echo -e "${red}Invalid option. Please try again.${nc}"
            sleep 2
            show_system_menu ;;
    esac
}

show_system_menu
