#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source library files in specific order
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/validation.sh"
source "${SCRIPT_DIR}/lib/docker.sh"
source "${SCRIPT_DIR}/lib/caddy.sh"
source "${SCRIPT_DIR}/lib/wordpress.sh"

echo "WordPress Site Setup Script"
echo "=========================="

setup_directories

FIRST_TIME=false
if ! check_container_running "caddy"; then
    FIRST_TIME=true
fi

while true; do
    read -p "Enter domain (e.g., example.com): " DOMAIN
    if validate_domain "$DOMAIN"; then
        break
    fi
done

while true; do
    read -p "Enter admin email: " ADMIN_EMAIL
    if validate_email "$ADMIN_EMAIL"; then
        break
    fi
done

read -p "Enter admin username: " ADMIN_USER

read -s -p "Enter password (press Enter for random password): " ADMIN_PASSWORD
echo

if [ -z "$ADMIN_PASSWORD" ]; then
    ADMIN_PASSWORD=$(generate_password)
    echo "Generated password: $ADMIN_PASSWORD"
fi

read -p "Enter site title: " SITE_TITLE

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)

WP_PROJECT_DIR="${WORDPRESS_DIR}/${DOMAIN}"
if [ -d "$WP_PROJECT_DIR" ]; then
    echo -e "${RED}Directory ${WP_PROJECT_DIR} already exists!${NC}"
    exit 1
fi

mkdir -p "$WP_PROJECT_DIR"
cd "$WP_PROJECT_DIR"

create_docker_compose "$DOMAIN" "$MYSQL_ROOT_PASSWORD" "$MYSQL_PASSWORD"
create_caddy_config "$DOMAIN"
create_wp_setup "$DOMAIN" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL" "$SITE_TITLE"
create_env_file "$DOMAIN" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL" "$MYSQL_ROOT_PASSWORD" "$MYSQL_PASSWORD"
 

while true; do
    read -p "Do you want to (1) start services and set up WordPress automatically or (2) do it manually later? [1/2]: " SETUP_CHOICE
    case $SETUP_CHOICE in
        1)
            if start_services "$FIRST_TIME" "$DOMAIN"; then
                if run_wp_setup "$DOMAIN"; then
                    echo -e "${GREEN}Complete setup finished successfully!${NC}"
                else
                    echo -e "${RED}WordPress setup failed. You may need to run setup manually later.${NC}"
                fi
            else
                echo -e "${RED}Service startup failed. You may need to start services manually.${NC}"
            fi
            break
            ;;
        2)
            echo -e "\n${BLUE}Manual setup instructions:${NC}"
            if [ "$FIRST_TIME" = true ]; then
                echo "1. Start Caddy:"
                echo "   cd ${CADDY_DIR} && docker compose up -d"
            fi
            echo "2. Start WordPress:"
            echo "   cd ${WP_PROJECT_DIR} && docker compose up -d"
            echo "3. Run the WordPress setup script:"
            echo "   ./wp-setup.sh"
            break
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
            ;;
    esac
done

echo -e "\n${BLUE}WordPress Site Information:${NC}"
echo "----------------------------------------"
echo "Domain: https://$DOMAIN"
echo "Admin URL: https://$DOMAIN/wp-admin"
echo "Username: $ADMIN_USER"
if [ "$PASSWORD_CHOICE" = "2" ]; then
    echo "Password: $ADMIN_PASSWORD (SAVE THIS PASSWORD!)"
fi
echo "Email: $ADMIN_EMAIL"
echo "----------------------------------------"

save_credentials "$WP_PROJECT_DIR" "$DOMAIN" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

echo -e "\nCredentials have been saved to: ${WP_PROJECT_DIR}/credentials.txt"

exit 0