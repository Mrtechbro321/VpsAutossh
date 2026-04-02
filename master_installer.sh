#!/bin/bash

green="\033[0;32m"
red="\033[0;31m"
blue="\033[0;34m"
yellow="\033[1;33m"
nc="\033[0m"

INSTALL_DIR="/opt/VpsAutossh"

log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }

# Check for root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Please use 'sudo su -' or run with sudo."
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Updating system and installing dependencies..."
    apt update -y > /dev/null 2>&1
    apt upgrade -y > /dev/null 2>&1
    apt install -y curl wget git unzip net-tools socat cron software-properties-common dirmngr apt-transport-https lsb-release ca-certificates gnupg jq nano > /dev/null 2>&1
    
    # Install gum for interactive UI
    if ! command -v gum &> /dev/null; then
        log_info "Installing gum for interactive UI..."
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        apt update -y > /dev/null 2>&1
        apt install -y gum > /dev/null 2>&1
        if ! command -v gum &> /dev/null; then
            log_warning "Gum installation failed. Menus will be text-based."
        else
            log_success "Gum installed successfully."
        fi
    else
        log_success "Gum is already installed."
    fi
    log_success "Core dependencies installed."
    
    # Ensure gum is in PATH for all users if installed
    if command -v gum &> /dev/null; then
        if ! grep -q "/usr/local/bin" /etc/profile; then
            echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile
            source /etc/profile
        fi
    fi
}

# Setup Xray
setup_xray() {
    log_info "Setting up Xray..."
    bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ install > /dev/null 2>&1
    mkdir -p /usr/local/etc/xray
    mkdir -p /var/log/xray
    
    # Basic Xray config (VLESS, VMess, Trojan over WebSocket + TLS)
    cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ]
}
EOF
    log_success "Xray setup complete."
}

# Setup Nginx
setup_nginx() {
    log_info "Setting up Nginx..."
    apt install -y nginx > /dev/null 2>&1
    systemctl enable nginx > /dev/null 2>&1
    log_success "Nginx setup complete."
}

# Setup SSL with acme.sh
setup_ssl() {
    log_info "Setting up SSL with acme.sh..."
    curl https://get.acme.sh | sh > /dev/null 2>&1
    ~/.acme.sh/acme.sh --install-cronjob --home "/root/.acme.sh" > /dev/null 2>&1
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt > /dev/null 2>&1
    
    # Issue certificate
    mkdir -p /etc/xray
    ~/.acme.sh/acme.sh --issue -d "$DOMAIN" --nginx \
      --keypath /etc/xray/xray.key \
      --fullchainpath /etc/xray/xray.crt > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "SSL certificate issued and installed."
    else
        log_error "Failed to issue SSL certificate. Please check your domain DNS records."
        exit 1
    fi
    log_success "SSL setup complete."
}

# Setup SSH and other services
setup_other_services() {
    log_info "Setting up SSH and other services..."
    # Dropbear
    apt install -y dropbear > /dev/null 2>&1
    echo "DROPBEAR_PORT=109" > /etc/default/dropbear
    echo "DROPBEAR_EXTRA_ARGS=\"-p 143\"" >> /etc/default/dropbear
    systemctl enable dropbear > /dev/null 2>&1
    systemctl restart dropbear > /dev/null 2>&1

    # Stunnel
    apt install -y stunnel4 > /dev/null 2>&1
    cat <<EOF > /etc/stunnel/stunnel.conf
client = no
[ssh]
accept = 444
connect = 127.0.0.1:22
[dropbear]
accept = 445
connect = 127.0.0.1:109
[dropbear-alt]
accept = 446
connect = 127.0.0.1:143
EOF
    openssl genrsa -out /etc/stunnel/key.pem 2048 > /dev/null 2>&1
    openssl req -new -x509 -key /etc/stunnel/key.pem -out /etc/stunnel/cert.pem -days 3650 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" > /dev/null 2>&1
    cat /etc/stunnel/key.pem /etc/stunnel/cert.pem > /etc/stunnel/stunnel.pem
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    systemctl enable stunnel4 > /dev/null 2>&1
    systemctl restart stunnel4 > /dev/null 2>&1

    # Squid Proxy
    apt install -y squid > /dev/null 2>&1
    cat <<EOF > /etc/squid/squid.conf
http_port 8080
acl localnet src 0.0.0.0/0
http_access allow localnet
http_access deny all
forwarded_for off
via off
EOF
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

    # WebSocket Proxy (for SSH over WS)
    cp "$INSTALL_DIR/service/systemd/ws-proxy.service" /etc/systemd/system/ws-proxy.service
    systemctl enable ws-proxy > /dev/null 2>&1
    systemctl start ws-proxy > /dev/null 2>&1

    # BadVPN UDPGW
    wget -O /usr/local/bin/badvpn-udpgw https://github.com/ambrop7/badvpn/raw/master/badvpn-udpgw > /dev/null 2>&1
    chmod +x /usr/local/bin/badvpn-udpgw
    cp "$INSTALL_DIR/service/systemd/badvpn-udpgw@.service" /etc/systemd/system/badvpn-udpgw@.service
    systemctl enable badvpn-udpgw@7200 > /dev/null 2>&1
    systemctl start badvpn-udpgw@7200 > /dev/null 2>&1
    systemctl enable badvpn-udpgw@7300 > /dev/null 2>&1
    systemctl start badvpn-udpgw@7300 > /dev/null 2>&1

    # SSHGuard (basic protection)
    apt install -y sshguard > /dev/null 2>&1
    systemctl enable sshguard > /dev/null 2>&1
    systemctl restart sshguard > /dev/null 2>&1

    log_success "Other services setup complete."
}

# Setup Firewall
setup_firewall() {
    log_info "Setting up firewall..."
    DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent > /dev/null 2>&1
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    iptables -F
    iptables -X
    iptables -Z
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT

    # Allow SSH (standard port)
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Allow HTTP and HTTPS
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT

    # Allow other service ports
    iptables -A INPUT -p tcp --dport 109 -j ACCEPT # Dropbear
    iptables -A INPUT -p tcp --dport 143 -j ACCEPT # Dropbear
    iptables -A INPUT -p tcp --dport 444 -j ACCEPT # Stunnel
    iptables -A INPUT -p tcp --dport 445 -j ACCEPT # Stunnel
    iptables -A INPUT -p tcp --dport 446 -j ACCEPT # Stunnel
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT # Squid
    iptables -A INPUT -p tcp --dport 8888 -j ACCEPT # WS Proxy
    iptables -A INPUT -p udp --dport 7200 -j ACCEPT # BadVPN
    iptables -A INPUT -p udp --dport 7300 -j ACCEPT # BadVPN

    # Save rules
    netfilter-persistent save > /dev/null 2>&1
    log_success "Firewall setup complete."
}

# Copy scripts and set permissions
copy_scripts() {
    log_info "Copying scripts and setting permissions..."
    DEST_DIR="/etc/vpsautossh"
    mkdir -p "$DEST_DIR"
    cp -r "$INSTALL_DIR/script" "$DEST_DIR/"
    cp "$INSTALL_DIR/uninstall.sh" "$DEST_DIR/"
    mkdir -p "$DEST_DIR/config"
    cp "$INSTALL_DIR/config/banner.conf" "$DEST_DIR/config/banner.conf"
    mkdir -p "$DEST_DIR/service/systemd"
    cp "$INSTALL_DIR/service/systemd/ws-proxy.service" "$DEST_DIR/service/systemd/ws-proxy.service"
    cp "$INSTALL_DIR/service/systemd/badvpn-udpgw@.service" "$DEST_DIR/service/systemd/badvpn-udpgw@.service"
    mkdir -p "$DEST_DIR/service/cron"
    cp "$INSTALL_DIR/service/cron/clean_expired_accounts" "$DEST_DIR/service/cron/clean_expired_accounts"
    cp "$INSTALL_DIR/service/cron/auto_reboot" "$DEST_DIR/service/cron/auto_reboot"
    chmod +x "$DEST_DIR/script/menu/"*.sh
    chmod +x "$DEST_DIR/script/ssh/"*.sh
    chmod +x "$DEST_DIR/script/xray/"*.sh
    chmod +x "$DEST_DIR/script/system/"*.sh
    chmod +x "$DEST_DIR/uninstall.sh"

    # Create symlinks for easy access
    ln -sf "$DEST_DIR/script/menu/main_menu.sh" /usr/local/bin/vpsman
    ln -sf "$DEST_DIR/script/menu/main_menu.sh" /usr/local/bin/myvpsman

    # Install cron jobs
    cp "$INSTALL_DIR/service/cron/clean_expired_accounts" /etc/cron.d/vpsautossh_clean_expired_accounts
    cp "$INSTALL_DIR/service/cron/auto_reboot" /etc/cron.d/vpsautossh_auto_reboot
    chmod 644 /etc/cron.d/vpsautossh_clean_expired_accounts
    chmod 644 /etc/cron.d/vpsautossh_auto_reboot

    log_success "Scripts copied and permissions set."
}

# Main installation flow
main_install() {
    check_root
    install_dependencies

    mkdir -p /etc/vpsautossh

    log_info "Do you want to use a domain name or the server's IP address?"
    echo "1) Use a Domain Name (Recommended for Xray/SSL)"
    echo "2) Use Server's IP Address (No SSL for Xray)"
    read -p "Choose an option (1 or 2): " DOMAIN_CHOICE

    case $DOMAIN_CHOICE in
        1)
            read -p "Enter your domain (e.g., example.com): " DOMAIN
            if [ -z "$DOMAIN" ]; then
                log_error "Domain cannot be empty. Exiting."
                exit 1
            fi
            # Basic domain validation (ensure it's not an IP address)
            if [[ "$DOMAIN" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                log_error "Invalid domain: You entered an IP address. Please enter a valid domain name (e.g., example.com)."
                exit 1
            fi
            USE_DOMAIN=true
            ;;
        2)
            DOMAIN=$(curl -s ifconfig.me)
            if [ -z "$DOMAIN" ]; then
                log_error "Could not retrieve server IP address. Exiting."
                exit 1
            fi
            log_info "Using server IP address: $DOMAIN"
            USE_DOMAIN=false
            ;;
        *)
            log_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    echo "$DOMAIN" > /etc/vpsautossh/domain

    setup_xray
    # Update Xray config with domain/IP
    sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" /usr/local/etc/xray/config.json
    
    if [ "$USE_DOMAIN" = true ]; then
        # Enable TLS in Xray config
        sed -i 's/"port": 10000,/"port": 443, "security": "tls", "tlsSettings": { "serverName": "YOUR_DOMAIN", "certificates": [ { "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" } ] },/g' /usr/local/etc/xray/config.json
        sed -i 's/"port": 10001,/"port": 443, "security": "tls", "tlsSettings": { "serverName": "YOUR_DOMAIN", "certificates": [ { "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" } ] },/g' /usr/local/etc/xray/config.json
        sed -i 's/"port": 10002,/"port": 443, "security": "tls", "tlsSettings": { "serverName": "YOUR_DOMAIN", "certificates": [ { "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" } ] },/g' /usr/local/etc/xray/config.json

        setup_nginx
        # Nginx reverse proxy config for Xray with SSL
        cat <<EOF > /etc/nginx/conf.d/reverse-proxy.conf
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
        rm /etc/nginx/sites-enabled/default > /dev/null 2>&1
        systemctl restart nginx > /dev/null 2>&1
        log_success "Nginx setup complete for domain."

        setup_ssl
    else
        log_warning "Skipping SSL setup as IP address is used. Xray will not use TLS."
        setup_nginx
        # Setup Nginx for HTTP only if using IP
        cat <<EOF > /etc/nginx/conf.d/reverse-proxy.conf
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    root /var/www/html;

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
        rm /etc/nginx/sites-enabled/default > /dev/null 2>&1
        systemctl restart nginx > /dev/null 2>&1
        log_success "Nginx setup complete for IP address."
    fi
    systemctl restart xray > /dev/null 2>&1
    setup_other_services
    setup_firewall
    copy_scripts

    log_success "VpsAutossh installation complete!"
    log_info "Type 'myvpsman' or 'vpsman' to access the management menu."
}

main_install
