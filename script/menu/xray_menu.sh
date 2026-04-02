#!/bin/bash

SCRIPT_DIR="/etc/vpsautossh"

# Source colors and common functions
source "$SCRIPT_DIR/script/common.sh" 2>/dev/null

# Display Xray menu
show_xray_menu() {
    clear
    echo -e "${green}===================================================${nc}"
    echo -e "${yellow}             XRAY ACCOUNT MANAGEMENT${nc}"
    echo -e "${green}===================================================${nc}"

    local options=(
        "Create Xray Account"
        "Delete Xray Account"
        "Renew Xray Account"
        "List All Xray Accounts"
        "Generate Xray Client Config"
        "Back to Main Menu"
    )

    local choice
    if command -v gum &> /dev/null; then
        choice=$(gum choose "${options[@]}" --header "XRAY MENU")
    else
        echo -e "${yellow}             XRAY MENU${nc}"
        echo -e "${green}===================================================${nc}"
        for i in "${!options[@]}"; do
            echo -e "${yellow}$((i+1)). ${options[$i]}${nc}"
        done
        echo -e "${green}===================================================${nc}"
        read -p "Enter your choice: " raw_choice
        case "$raw_choice" in
            1) choice="Create Xray Account" ;;
            2) choice="Delete Xray Account" ;;
            3) choice="Renew Xray Account" ;;
            4) choice="List All Xray Accounts" ;;
            5) choice="Generate Xray Client Config" ;;
            6) choice="Back to Main Menu" ;;
            *) choice="Invalid" ;;
        esac
    fi

    clear
    case "$choice" in
        "Create Xray Account") "$SCRIPT_DIR/script/xray/create_xray_account.sh" ;;
        "Delete Xray Account") "$SCRIPT_DIR/script/xray/delete_xray_account.sh" ;;
        "Renew Xray Account") "$SCRIPT_DIR/script/xray/renew_xray_account.sh" ;;
        "List All Xray Accounts") "$SCRIPT_DIR/script/xray/list_xray_accounts.sh" ;;
        "Generate Xray Client Config") "$SCRIPT_DIR/script/xray/generate_xray_config.sh" ;;
        "Back to Main Menu") "$SCRIPT_DIR/script/menu/main_menu.sh" ;;
        *)
            echo -e "${red}Invalid option. Please try again.${nc}"
            sleep 2
            show_xray_menu ;;
    esac
}

show_xray_menu
