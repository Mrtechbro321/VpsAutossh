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
XRAY_CONFIG_PATH="/usr/local/etc/xray/config.json"

change_domain() {
    log_info "Changing domain..."
    CURRENT_DOMAIN=$(cat "$SCRIPT_DIR/domain" 2>/dev/null || echo "Not Set")
    log_info "Current Domain: ${CURRENT_DOMAIN}"
    NEW_DOMAIN=$(gum input --placeholder "Enter new domain (e.g., new.example.com)")

    if [[ -z "$NEW_DOMAIN" ]]; then
        log_error "New domain cannot be empty."
        return 1
    fi

    if gum confirm "Are you sure you want to change the domain from ${CURRENT_DOMAIN} to ${NEW_DOMAIN}?"; then
        echo "$NEW_DOMAIN" > "$SCRIPT_DIR/domain"
        log_success "Domain file updated."

        log_info "Updating Nginx configuration..."
        sed -i "s/server_name ${CURRENT_DOMAIN};/server_name ${NEW_DOMAIN};/g" /etc/nginx/conf.d/reverse-proxy.conf
        sed -i "s/serverName": "${CURRENT_DOMAIN}"/serverName": "${NEW_DOMAIN}"/g" "$XRAY_CONFIG_PATH"
        systemctl restart nginx > /dev/null 2>&1
        log_success "Nginx configuration updated."

        log_info "Renewing SSL certificate..."
        # Remove old certs
        rm -f /etc/xray/xray.key /etc/xray/xray.crt
        ~/.acme.sh/acme.sh --issue -d "$NEW_DOMAIN" --nginx \
          --keypath /etc/xray/xray.key \
          --fullchainpath /etc/xray/xray.crt > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log_success "SSL certificate renewed successfully."
        else
            log_error "Failed to renew SSL certificate. Please check your DNS records."
            return 1
        fi
        systemctl restart xray > /dev/null 2>&1
        log_success "Domain successfully changed to ${NEW_DOMAIN}."
    else
        log_info "Domain change cancelled."
    fi
}

change_domain
gum confirm "Back to Main Menu?" && "$SCRIPT_DIR/scripts/menu/main_menu.sh"
