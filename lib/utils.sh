#!/bin/bash

function generate_password() {
    openssl rand -base64 12
}
export -f generate_password

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

function save_credentials() {
    local WP_PROJECT_DIR=$1
    local DOMAIN=$2
    local ADMIN_USER=$3
    local ADMIN_PASSWORD=$4
    local ADMIN_EMAIL=$5

    cat > "${WP_PROJECT_DIR}/credentials.txt" <<EOL
WordPress Site Credentials
========================
Domain: https://${DOMAIN}
Admin URL: https://${DOMAIN}/wp-admin
Username: ${ADMIN_USER}
Password: ${ADMIN_PASSWORD}
Email: ${ADMIN_EMAIL}
------------------------
Directory Information:
WordPress: ${WP_PROJECT_DIR}
Caddy Config: ${CADDY_DIR}/sites/${DOMAIN}.caddy
========================
Generated on: $(date)
EOL

    chmod 600 "${WP_PROJECT_DIR}/credentials.txt"
}
export -f save_credentials