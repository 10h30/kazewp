#!/bin/bash

# Get the directory where the script is located

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/src"

# Source library files in specific order
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/validation.sh"
source "${SCRIPT_DIR}/lib/docker.sh"
source "${SCRIPT_DIR}/lib/caddy.sh"
source "${SCRIPT_DIR}/lib/wordpress.sh"
source "${SCRIPT_DIR}/lib/menu.sh"

# Check if Docker is installed
if ! command_exists docker; then
    install_docker
    
    # Verify installation
    if ! command_exists docker; then
        echo "Docker installation failed. Please install Docker manually."
        exit 1
    fi
fi

# Check if Docker service is running
if [ "$(uname)" == "Darwin" ]; then
  # macOS
  if ! docker info > /dev/null 2>&1; then
    echo "Docker service is not running. Starting Docker..."
    open -a Docker
  fi
else
  # Linux
  if ! systemctl is-active --quiet docker; then
    echo "Docker service is not running. Starting Docker..."
    sudo systemctl start docker
  fi
fi

# Main script
case "$1" in
    "install")
        DOMAIN="$2"
        if [ -z "$DOMAIN" ]; then
            echo "Error: Please provide a domain"
            while true; do
                read -p "Enter domain (e.g., example.com): " DOMAIN
                if validate_domain "$DOMAIN"; then
                    break
                fi
            done
        fi
        install_site "$DOMAIN"
        ;;
    "list")
        list_sites
        ;;
    "delete")
        if [ -z "$2" ]; then
            show_action_menu "delete"
        else
            delete_sites "$2"
        fi
        
        ;;
    "stop")
        if [ -z "$2" ]; then
            show_action_menu "stop"
        else
            stop_sites "$2"
        fi
        ;;
    "start")
        if [ -z "$2" ]; then
            show_action_menu "start"
        else
            start_sites "$2"
        fi
        ;;
    "restart")
        if [ -z "$2" ]; then
            show_action_menu "restart"
        else
            restart_sites "$2"
        fi
        ;;
    *)
        show_interactive_menu
        ;;
esac