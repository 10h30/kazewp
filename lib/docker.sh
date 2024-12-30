#!/bin/bash

check_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
    return $?
}

create_docker_compose() {
    export DOMAIN=$1
    export MYSQL_ROOT_PASSWORD=$2
    export MYSQL_PASSWORD=$3

    envsubst < "${SCRIPT_DIR}/templates/docker-compose.yml.template" > compose.yaml
    #envsubst '$DOMAIN $MYSQL_ROOT_PASSWORD $MYSQL_PASSWORD' < "${SCRIPT_DIR}/templates/docker-compose.yml.template" > compose.yaml

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