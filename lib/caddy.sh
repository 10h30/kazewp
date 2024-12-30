#!/bin/bash

reload_caddy() {
    echo "Reloading Caddy configuration..."
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile
}

create_caddy_config() {
    export DOMAIN=$1
    export CONFIG_FILE="${CADDY_DIR}/sites/${DOMAIN}.caddy"

    mkdir -p "${CADDY_DIR}/sites"

    envsubst < "${SCRIPT_DIR}/templates/caddy.template" > "$CONFIG_FILE"

    if ! grep -q "import sites/\*.caddy" "${CADDY_DIR}/Caddyfile"; then
        echo 'import sites/*.caddy' >> "${CADDY_DIR}/Caddyfile"
    fi
}

create_caddy_docker_compose() {
    mkdir -p "${CADDY_DIR}"
    
    # Create necessary directories
    mkdir -p "${CADDY_DIR}/sites"
    mkdir -p "${CADDY_DIR}/caddy_data"
    mkdir -p "${CADDY_DIR}/caddy_config"

    # Create initial Caddyfile
    cat > "${CADDY_DIR}/Caddyfile" <<EOL
{
    # Global options
    admin off
    persist_config off
}

# Site configurations will be imported below
import sites/*.caddy
EOL

    # Create docker-compose.yaml
    cat > "${CADDY_DIR}/compose.yaml" <<EOL
services:
  caddy:
    container_name: caddy
    image: caddy:latest
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./sites:/etc/caddy/sites
      - ./caddy_data:/data
      - ./caddy_config:/config
      - ../wordpress:/var/www
    networks:
      - caddy_net

networks:
  caddy_net:
    name: caddy_net
EOL
}

setup_directories() {
    mkdir -p "${WORDPRESS_DIR}"
    mkdir -p "${CADDY_DIR}/sites"
    mkdir -p "${CADDY_DIR}/caddy_data"
    mkdir -p "${CADDY_DIR}/caddy_config"

    if [ ! -f "${CADDY_DIR}/Caddyfile" ]; then
        echo "Creating initial Caddy configuration..."
        create_caddy_docker_compose
    fi
}