#!/bin/bash

# Function to install Docker
install_docker() {
    # Detect OS
    OS=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi

    # Function to install curl if missing
    install_curl() {
        if ! command -v curl &>/dev/null; then
            echo "curl is not installed. Installing curl..."
            case "$OS" in
            ubuntu | debian)
                sudo apt update && sudo apt install -y curl
                ;;
            centos | rhel | rocky | alma)
                sudo yum install -y curl
                ;;
            fedora)
                sudo dnf install -y curl
                ;;
            arch)
                sudo pacman -Sy --noconfirm curl
                ;;
            *)
                echo "Unsupported OS: $OS. Please install curl manually."
                exit 1
                ;;
            esac
        fi
    }

    # Install curl if missing
    install_curl

    # Check if Docker is already installed
    if command -v docker &>/dev/null; then
        echo "Docker is already installed."
        return
    fi

    # Prompt user to install Docker
    echo -n "Docker is not installed. Do you want to install Docker? (y/n): "
    read answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh

        # Add the current user to the docker group
        sudo usermod -aG docker $USER

        echo "Docker has been installed successfully!"
        echo "You may need to log out and back in for group changes to take effect."
    else
        echo "Docker installation skipped. Please install Docker manually to use this script."
        exit 1
    fi
}

check_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
    return $?
}

create_docker_compose() {
    export DOMAIN=$1
    local USE_PHPMYADMIN=$4


    # Define phpMyAdmin service block
    PHPMYADMIN_BLOCK=$(
        cat <<-EOL
  phpmyadmin_${DOMAIN}:
    container_name: phpmyadmin_${DOMAIN}
    depends_on:
      - db_${DOMAIN}
    image: phpmyadmin/phpmyadmin
    environment:
      - PMA_HOST=db_${DOMAIN}
      - MYSQL_ROOT_PASSWORD=\${MYSQL_ROOT_PASSWORD}
      - PMA_ABSOLUTE_URI=https://${DOMAIN}/pma/
    restart: always
    networks:
      - ${DOMAIN}_net
      - caddy_net
EOL
    )

    # Process Docker Compose template
    if [[ "$USE_PHPMYADMIN" == "y" ]]; then
        export PHPMYADMIN_BLOCK="$PHPMYADMIN_BLOCK"
    else
        export PHPMYADMIN_BLOCK=""
    fi
    envsubst <"${SCRIPT_DIR}/templates/docker-compose.yml.template" >compose.yaml

    echo "Docker Compose file created successfully."

}

start_services() {
    local FIRST_TIME=$1
    local DOMAIN=$2

    if [ "$FIRST_TIME" = true ]; then
        echo "Starting Caddy server..."
        cd "${CADDY_DIR}"
        docker compose up -d
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to start Caddy server${NC}"
            return 1
        fi
    else
        # Check if Caddy is running and reload configuration
        if check_container_running "caddy"; then
            reload_caddy
        else
            echo -e "${RED}Caddy is not running. Please start it first${NC}"
            return 1
        fi
    fi

    echo "Starting WordPress for ${DOMAIN}..."
    cd "${WORDPRESS_DIR}/${DOMAIN}"
    docker compose up -d
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to start WordPress services${NC}"
        return 1
    fi

    return 0
}

get_containers_status() {
    local compose_file="$1"
    local containers=()
    local count=0

    while IFS= read -r container; do
        # Skip if empty line
        [ -z "$container" ] && continue
        containers+=("$container")
        ((count++))
    done < <(docker compose -f "$compose_file" ps --status running --format '{{.Name}}')

    if [ $count -eq 0 ]; then
        echo "Status: No container is running"
    else
        echo -n "Status: $count containers are running: "
        printf "%s" "${containers[0]}"
        for ((i = 1; i < ${#containers[@]}; i++)); do
            printf " and %s" "${containers[$i]}"
        done
        echo
    fi
}
