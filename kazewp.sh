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

# Function to install a new WordPress site
install_site() {

    FIRST_TIME=false
    if ! check_container_running "caddy"; then
        FIRST_TIME=true
    fi

    setup_directories

    DOMAIN="$1"
    #db_prefix="$(openssl rand -base64 6)"_


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
                reload_caddy
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
    echo "Domain:       https://$DOMAIN"
    echo "Admin URL:    https://$DOMAIN/wp-admin"
    echo "Username:     $ADMIN_USER"
    echo "Password:     $ADMIN_PASSWORD (SAVE THIS PASSWORD!)"
    echo "Email:        $ADMIN_EMAIL"
    echo "----------------------------------------"

save_credentials "$WP_PROJECT_DIR" "$DOMAIN" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

echo -e "\nCredentials have been saved to: ${WP_PROJECT_DIR}/credentials.txt"

exit 0
}

# Function to list all installed WordPress sites
list_sites() {
    if [ ! -d "$WORDPRESS_DIR" ]; then
        echo "There are no websites setup yet!"
        exit 1
    fi
    echo "Installed WordPress Sites:"
    echo "-------------------------"
    subfolders=($(find "$WORDPRESS_DIR" -mindepth 1 -maxdepth 1 -type d))
    if [ ${#subfolders[@]} -eq 0 ]; then
    echo "There are no websites setup yet!"
    else
        for site in "$WORDPRESS_DIR"/*; do
            if [ -d "$site" ]; then
                DOMAIN=$(basename "$site")
                if [ -f "$site/compose.yaml" ]; then
                    echo "Site: $DOMAIN"
                    echo "Path: $site"
                    get_containers_status "$site/compose.yaml"
                    #echo "Status: $(docker compose -f $site/compose.yaml ps --status running | grep -v 'Name' | wc -l) containers running"
                    echo "-------------------------"
                fi
            fi
        done
    fi
}

# Function to delete a WordPress site
delete_site() {
    DOMAIN="$1"
    WP_PROJECT_DIR="${WORDPRESS_DIR}/${DOMAIN}"
    
    #echo $DOMAIN
    #echo $WP_PROJECT_DIR

    if [ ! -d "$WP_PROJECT_DIR" ]; then
        echo "Error: Site '$DOMAIN' not found"
        return 1
    fi
        
    echo "Warning: This will permanently delete the site: $DOMAIN"
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Operation cancelled"
        return 0
    fi
    
    echo "Stopping Docker containers..."
    docker compose -f "$WP_PROJECT_DIR/compose.yaml" down
    
    echo "Removing site directory..."
    rm -rf "$WP_PROJECT_DIR"
    
    echo "Removing Caddy configuration..."
    rm -f "${CADDY_DIR}/sites/${DOMAIN}.caddy"
    
    echo "Reloading Caddy..."
    reload_caddy
    
    echo "Site '$DOMAIN' has been successfully deleted"
}

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

        # Check if correct arguments are provided
        if [ "$2" == "all" ]; then
            # Ask for confirmation before proceeding with the uninstallation
            read -p "Are you sure you want to uninstall everything? This will stop and remove all containers, and delete files. (Y/n): " confirm

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Stop all running containers
                echo "Stopping all containers..."
                find . -name 'compose.yaml' -execdir docker compose down \;

                # Remove WordPress files
                echo "Removing WordPress files..."
                rm -rf wordpress

                # Remove Caddy files
                echo "Removing Caddy files..."
                rm -rf caddy

                docker system prune -af 

                echo "Uninstallation complete."
            else
                echo "Uninstallation aborted."
            fi
        else
            if [ -z "$2" ]; then
                echo "Error: Please provide a site name to delete or using all to delete everything"
                #list_sites
                while true; do
                    read -p "Enter domain (e.g., example.com): " DOMAIN
                    if validate_domain "$DOMAIN"; then
                        break
                    fi
                done
                delete_site "$DOMAIN"
            else
                delete_site "$2"
            fi
        fi

        
        ;;

    *)
        echo "KazeW - PWordPress Site Management Script"
        echo "Usage:"
        echo "  $0 install <domain>              - Install a new WordPress site"
        echo "  $0 list                          - List all installed WordPress sites"
        echo "  $0 delete <domain>            - Delete a WordPress site"
        echo "  $0 delete all                    - Delete everything"
        exit 1
        ;;
esac