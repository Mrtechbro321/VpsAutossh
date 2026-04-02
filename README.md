# VpsAutossh - All-in-One VPS Management Script


## Introduction

VpsAutossh is a comprehensive collection of scripts designed to simplify and automate the management of your Virtual Private Server (VPS). It allows you to easily install, configure, and manage SSH accounts, Xray (VLESS, VMess, Trojan) protocols, and other essential services.

## Features

*   **SSH Account Management:** Create, delete, renew, and lock/unlock SSH users.
*   **Xray Protocol Support:** Manage Xray accounts for VLESS, VMess, and Trojan protocols.
*   **Service Management:** Control critical services like Nginx, Stunnel, Squid, Dropbear, BadVPN, and more.
*   **Automated SSL:** Automatic SSL certificate installation and renewal using `acme.sh`.
*   **System Information:** View detailed system information of your VPS.
*   **User-Friendly Interface:** An interactive and engaging command-line interface using the `gum` tool.
*   **Uninstall Option:** Easily remove the script and all installed services.

## Installation

To install VpsAutossh on your VPS, follow these steps:

1.  **Log in as root user:**
    ```bash
    sudo su -
    ```

2.  **Download and run the master installer script:**
    ```bash
    bash <(curl -Ls https://raw.githubusercontent.com/Mrtechbro321/VpsAutossh/main/install.sh)
    ```
    The installer will prompt you to enter a domain name. Ensure your domain points to your VPS's IP address.

## Usage

After installation, you can access the main menu by running either of the following commands:

```bash
myvpsman
# or
vpsman
```

This will present you with an interactive menu where you can select various management tasks.

## Structure

The VpsAutossh repository structure is as follows:

```
VpsAutossh/
├── master_installer.sh       # Main installation script
├── uninstall.sh              # Script to uninstall the script and services
├── README.md                 # This file
├── Developer_Info.md         # Developer information
├── scripts/
│   ├── menu/                 # Menu-related scripts
│   │   ├── main_menu.sh
│   │   ├── ssh_menu.sh
│   │   ├── xray_menu.sh
│   │   └── system_menu.sh
│   ├── ssh/                  # SSH management scripts
│   │   ├── create_ssh_account.sh
│   │   ├── delete_ssh_account.sh
│   │   ├── renew_ssh_account.sh
│   │   ├── lock_unlock_ssh_account.sh
│   │   └── edit_ssh_banner.sh
│   ├── xray/                 # Xray management scripts
│   │   ├── create_xray_account.sh
│   │   ├── delete_xray_account.sh
│   │   ├── renew_xray_account.sh
│   │   ├── list_xray_accounts.sh
│   │   └── generate_xray_config.sh
│   └── system/               # System management scripts
│       ├── change_domain.sh
│       ├── manage_services.sh
│       └── system_info.sh
└── config/                   # Configuration files (e.g., banner.conf)
```

## Contributing

Contributions are always welcome! If you have any suggestions, bug reports, or improvements, please open a pull request or file an issue.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

## Contact

If you have any questions or feedback, please reach out at [@RajTechowner].
