#!/bin/bash

reload_caddy() {
    echo "Reloading Caddy configuration..."
    cd "$CADDY_DIR" && docker compose restart
}

create_caddy_config() {
    export DOMAIN=$1
    export CONFIG_FILE="${CADDY_DIR}/sites/${DOMAIN}.caddy"

    mkdir -p "${CADDY_DIR}/sites"


    # Define phpMyAdmin service block
    PHPMYADMIN_CADDY_BLOCK=$(
        cat <<-EOL
    # Redirect /pma to /pma/
    redir /pma /pma/ 301
    # Route requests for /pma (and subpaths) to the phpMyAdmin container
    handle_path /pma* {
        reverse_proxy phpmyadmin_${DOMAIN}
    }
EOL
    )



    if [[ "$USE_PHPMYADMIN" == "y" ]]; then
        export PHPMYADMIN_CADDY_BLOCK="$PHPMYADMIN_CADDY_BLOCK"
    else
        export PHPMYADMIN_CADDY_BLOCK=""
    fi

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
(wordpress) {

	# Some static files Cache-Control.
	@static {
		path *.ico *.css *.js *.gif *.jpg *.jpeg *.png *.svg *.woff *.json
	}
	header @static Cache-Control max-age=2592000

	# Security
        @forbidden {
                not path /wp-includes/ms-files.php
                path /wp-admin/includes/*.php
                path /wp-includes/*.php
                path /wp-config.php
                path /wp-content/uploads/*.php
                path /.user.ini
                path /wp-content/debug.log
        }
        respond @forbidden "Access denied" 403

	# Cache Enabler
	@cache_enabler {
		not header_regexp Cookie "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_logged_in"
		not path_regexp "(/wp-admin/|/xmlrpc.php|/wp-(app|cron|login|register|mail).php|wp-.*.php|/feed/|index.php|wp-comments-popup.php|wp-links-opml.php|wp-locations.php|sitemap(index)?.xml|[a-z0-9-]+-sitemap([0-9]+)?.xml)"
		not method POST
		not expression {query} != ''
	}

	route @cache_enabler {
		try_files /wp-content/cache/cache-enabler/{host}{uri}/https-index.html /wp-content/cache/cache-enabler/{host}{uri}/index.html {path} {path}/index.php?{query}
	}
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
        #echo "Creating initial Caddy configuration..."
        create_caddy_docker_compose
    fi
}