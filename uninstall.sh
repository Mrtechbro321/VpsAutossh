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

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root."
        exit 1
    fi
}

uninstall_script() {
    check_root
    log_info "Stopping and disabling all services..."
    systemctl stop xray > /dev/null 2>&1
    systemctl disable xray > /dev/null 2>&1
    systemctl stop nginx > /dev/null 2>&1
    systemctl disable nginx > /dev/null 2>&1
    systemctl stop dropbear > /dev/null 2>&1
    systemctl disable dropbear > /dev/null 2>&1
    systemctl stop stunnel4 > /dev/null 2>&1
    systemctl disable stunnel4 > /dev/null 2>&1
    systemctl stop ws-proxy > /dev/null 2>&1
    systemctl disable ws-proxy > /dev/null 2>&1
    systemctl stop badvpn-udpgw@7200 > /dev/null 2>&1
    systemctl disable badvpn-udpgw@7200 > /dev/null 2>&1
    systemctl stop badvpn-udpgw@7300 > /dev/null 2>&1
    systemctl disable badvpn-udpgw@7300 > /dev/null 2>&1
    systemctl stop squid > /dev/null 2>&1
    systemctl disable squid > /dev/null 2>&1
    systemctl stop sshguard > /dev/null 2>&1
    systemctl disable sshguard > /dev/null 2>&1
    service cron restart > /dev/null 2>&1 # Restart cron to remove jobs

    log_info "Removing files and directories..."
    rm -rf /etc/vpsautossh
    rm -rf /usr/local/etc/xray
    rm -rf /var/log/xray
    rm -f /etc/nginx/conf.d/reverse-proxy.conf
    rm -f /etc/default/dropbear
    rm -f /etc/stunnel/stunnel.conf
    rm -f /etc/stunnel/{key.pem,cert.pem,stunnel.pem}
    rm -f /etc/squid/squid.conf
    rm -f /etc/systemd/system/ws-proxy.service
    rm -f /etc/systemd/system/badvpn-udpgw@.service
    rm -f /etc/cron.d/clean_expired_accounts
    rm -f /etc/cron.d/auto_reboot
    rm -f /usr/local/bin/gum
    rm -f /usr/local/bin/ws-proxy
    rm -f /usr/local/bin/badvpn-udpgw
    rm -f /usr/bin/myvpsman /usr/bin/vpsman

    # Remove acme.sh if installed by this script
    if [ -d "$HOME/.acme.sh" ]; then
        ~/.acme.sh/acme.sh --uninstall > /dev/null 2>&1
        rm -rf "$HOME/.acme.sh"
    fi

    log_info "Cleaning firewall rules..."
    iptables -F
    iptables -X
    iptables -Z
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    netfilter-persistent save > /dev/null 2>&1

    log_info "Removing extra packages..."
    apt purge -y stunnel4 nginx dropbear socat sshguard squid > /dev/null 2>&1
    apt autoremove -y > /dev/null 2>&1
    apt autoclean -y > /dev/null 2>&1

    log_success "VpsAutossh script uninstalled successfully."
}

uninstall_script
