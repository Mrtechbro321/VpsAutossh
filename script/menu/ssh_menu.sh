#!/bin/bash

SCRIPT_DIR="/etc/vpsautossh"

# Source colors and common functions
source "$SCRIPT_DIR/script/common.sh" 2>/dev/null

# Display SSH menu
show_ssh_menu() {
    clear
    echo -e "${green}===================================================${nc}"
    echo -e "${yellow}             SSH ACCOUNT MANAGEMENT${nc}"
    echo -e "${green}===================================================${nc}"

    local options=(
        "Create SSH Account"
        "Delete SSH Account"
        "Renew SSH Account"
        "Lock/Unlock SSH Account"
        "Edit SSH Banner"
        "Back to Main Menu"
    )

    local choice
    if command -v gum &> /dev/null; then
        choice=$(gum choose "${options[@]}" --header "SSH MENU")
    else
        echo -e "${yellow}             SSH MENU${nc}"
        echo -e "${green}===================================================${nc}"
        for i in "${!options[@]}"; do
            echo -e "${yellow}$((i+1)). ${options[$i]}${nc}"
        done
        echo -e "${green}===================================================${nc}"
        read -p "Enter your choice: " raw_choice
        case "$raw_choice" in
            1) choice="Create SSH Account" ;;
            2) choice="Delete SSH Account" ;;
            3) choice="Renew SSH Account" ;;
            4) choice="Lock/Unlock SSH Account" ;;
            5) choice="Edit SSH Banner" ;;
            6) choice="Back to Main Menu" ;;
            *) choice="Invalid" ;;
        esac
    fi

    clear
    case "$choice" in
        "Create SSH Account") "$SCRIPT_DIR/script/ssh/create_ssh_account.sh" ;;
        "Delete SSH Account") "$SCRIPT_DIR/script/ssh/delete_ssh_account.sh" ;;
        "Renew SSH Account") "$SCRIPT_DIR/script/ssh/renew_ssh_account.sh" ;;
        "Lock/Unlock SSH Account") "$SCRIPT_DIR/script/ssh/lock_unlock_ssh_account.sh" ;;
        "Edit SSH Banner") "$SCRIPT_DIR/script/ssh/edit_ssh_banner.sh" ;;
        "Back to Main Menu") "$SCRIPT_DIR/script/menu/main_menu.sh" ;;
        *)
            echo -e "${red}Invalid option. Please try again.${nc}"
            sleep 2
            show_ssh_menu ;;
    esac
}

show_ssh_menu
