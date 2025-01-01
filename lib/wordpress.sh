#!/bin/bash

wait_for_wordpress() {
    local DOMAIN=$1
    local MAX_ATTEMPTS=30
    local ATTEMPT=1

    echo "Waiting for WordPress to be ready..."
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        #if docker run --rm --network container:wordpress_${DOMAIN} wordpress:cli-php8.1 wp core is-installed > /dev/null 2>&1; then
        if docker compose run --rm wpcli core is-installed > /dev/null 2>&1; then
            return 0
        fi
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS..."
        sleep 10
        ATTEMPT=$((ATTEMPT + 1))
    done
    return 1
}

create_env_file() {
    export DOMAIN=$1
    export ADMIN_USER=$2
    export ADMIN_PASSWORD=$3
    export ADMIN_EMAIL=$4
    export MYSQL_ROOT_PASSWORD=$5
    export MYSQL_PASSWORD=$6

    # Output file
    ENV_FILE=".env"
    # Generate .env file
    #echo "Generating $ENV_FILE..."

    cat <<EOL > "${WP_PROJECT_DIR}/$ENV_FILE"
    DOMAIN_NAME = ${DOMAIN}

    ## Wordpress ##
    WORDPRESS_DB_USER=wordpress
    WORDPRESS_DB_PASSWORD=${MYSQL_PASSWORD}
    WORDPRESS_DB_NAME=wordpress
    WORDPRESS_DB_HOST=db_${DOMAIN}:3306

    # Website Credentials
    WORDPRESS_ADMIN_USER=${ADMIN_USER}
    WORDPRESS_ADMIN_PASSWORD=${ADMIN_PASSWORD}
    WORDPRESS_ADMIN_EMAIL=${ADMIN_EMAIL}

    ## MYSQL ##
    MYSQL_USER=wordpress
    MYSQL_PASSWORD=${MYSQL_PASSWORD}
    MYSQL_DATABASE=wordpress
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    
EOL

    #echo "$ENV_FILE generated successfully!"
}


create_wp_setup() {
    export DOMAIN=$1
    export ADMIN_USER=$2
    export ADMIN_PASSWORD=$3
    export ADMIN_EMAIL=$4
    export SITE_TITLE=$5

    envsubst '$DOMAIN $ADMIN_USER $ADMIN_PASSWORD $ADMIN_EMAIL $SITE_TITLE' < "${SCRIPT_DIR}/templates/wp-setup.sh.template" > wp-setup.sh
    chmod +x wp-setup.sh
}

run_wp_setup() {
    local DOMAIN=$1

    echo "Running WordPress setup..."
    cd "${WORDPRESS_DIR}/${DOMAIN}"

    #if ! wait_for_wordpress "$DOMAIN"; then
    #    echo -e "${RED}WordPress failed to start properly${NC}"
    #    return 1
    #fi

    if ./wp-setup.sh 2>&1; then
        echo -e "${GREEN}WordPress setup completed successfully${NC}"
        return 0
    else
        echo -e "${RED}WordPress setup failed${NC}"
        return 1
    fi
}