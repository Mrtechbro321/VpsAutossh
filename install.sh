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

# Check for root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Please use 'sudo su -' or run with sudo."
        exit 1
    fi
}

# Install git and unzip if not present
install_prerequisites() {
    log_info "Installing git and unzip if not present..."
    apt update -y > /dev/null 2>&1
    apt install -y git unzip > /dev/null 2>&1
    log_success "Prerequisites installed."
}

# Main installation flow for the one-liner
main_one_liner_install() {
    check_root
    install_prerequisites

    REPO_URL="https://github.com/Mrtechbro321/VpsAutossh.git"
    INSTALL_DIR="/opt/VpsAutossh"

    log_info "Cloning VpsAutossh repository from ${REPO_URL}..."
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "Existing VpsAutossh installation found at ${INSTALL_DIR}. Removing it..."
        rm -rf "$INSTALL_DIR"
    fi
    git clone "$REPO_URL" "$INSTALL_DIR" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "Repository cloned successfully to ${INSTALL_DIR}."
        log_info "Starting the main VpsAutossh installer..."
        chmod +x "${INSTALL_DIR}/master_installer.sh"
        bash "${INSTALL_DIR}/master_installer.sh"
    else
        log_error "Failed to clone VpsAutossh repository. Please check the URL and your internet connection."
        exit 1
    fi
}

main_one_liner_install
