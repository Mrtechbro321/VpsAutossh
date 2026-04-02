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

clean_expired_ssh_accounts() {
    log_info "Cleaning expired SSH accounts..."
    EXPIRED_USERS=$(awk -F: 
    if [ -n "$EXPIRED_USERS" ]; then
        for USERNAME in $EXPIRED_USERS; do
            userdel -r "$USERNAME" &>/dev/null
            log_success "Expired SSH user ${USERNAME} removed."
        done
    else
        log_info "No expired SSH accounts found."
    fi
}

clean_expired_xray_accounts() {
    log_info "Cleaning expired Xray accounts..."
    if [ ! -f "$XRAY_USERS_DB" ] || [ "$(jq -r ".[] | select(.expiry_date < $(date +%s))" "$XRAY_USERS_DB" | jq -r ".username" | wc -l)" -eq 0 ]; then
        log_info "No expired Xray accounts found."
        return 0
    fi

    EXPIRED_USERS=$(jq -r ".[] | select(.expiry_date < $(date +%s))" "$XRAY_USERS_DB")
    
    if [ -n "$EXPIRED_USERS" ]; then
        echo "$EXPIRED_USERS" | while read -r USER_DATA;
        do
            USERNAME=$(echo "$USER_DATA" | jq -r ".username")
            PROTOCOL=$(echo "$USER_DATA" | jq -r ".protocol")
            INBOUND_TAG="${PROTOCOL}-in"

            # Remove user via Xray API
            curl -s -X POST \
                -H "Content-Type: application/json" \
                "http://127.0.0.1:8010/traffic" \
                -d "{\"command\": \"removeInboundUser\", \"tag\": \"${INBOUND_TAG}\", \"email\": \"${USERNAME}\"}" > /dev/null

            log_success "Expired Xray user ${USERNAME} (${PROTOCOL}) removed."
        done
        jq "del(.[] | select(.expiry_date < $(date +%s)))" "$XRAY_USERS_DB" > "${XRAY_USERS_DB}.tmp" && mv "${XRAY_USERS_DB}.tmp" "$XRAY_USERS_DB"
    fi
}

clean_expired_ssh_accounts
clean_expired_xray_accounts
