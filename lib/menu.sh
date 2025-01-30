#!/bin/bash

# lib/menu.sh

# Show the main interactive menu
show_interactive_menu() {
    print_header "KazeWP - WordPress Site Management"
    print_separator    
    print_subheader "Quick Usage:"
    print_info "  $0 list                          - List all installed WordPress sites"
    print_info "  $0 install <domain>              - Install a new WordPress site"
    print_info "  $0 stop <domain>                 - Stop running WordPress sites"
    print_info "  $0 start <domain>                - Start an installed WordPress sites"
    print_info "  $0 delete <domain>               - Delete a WordPress site"
    print_info "  $0 delete all                    - Delete everything"
    
    # First check if any sites exist
    if [ ! -d "$WORDPRESS_DIR" ] || [ -z "$(ls -A "$WORDPRESS_DIR" 2>/dev/null)" ]; then
        print_warning "No WordPress sites installed yet."
        show_action_menu "brand-new"
        return
    fi

    # Get and display existing sites
    local -a sites=()
    local i=1
    
    print_subheader "Installed WordPress Sites"
    while IFS= read -r site; do
        if [ -f "$site/compose.yaml" ]; then
            sites+=("$(basename "$site")")
            domain=$(basename "$site")
            status=$(get_site_status "$site/compose.yaml")
            print_menu_item "$i" "$domain" "$status"
            ((i++))
        fi
    done < <(find "$WORDPRESS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

    print_subheader "Available Actions"
    echo -e "${BWHITE}Select an option:${NC}"
    print_menu_action "n" "Install new WordPress site"
    print_menu_action "m" "Manage multiple sites"
    print_menu_action "q" "Quit"
    print_separator

    read -p "$(echo -e ${BCYAN}⮕${NC}) " CHOICE

    case $CHOICE in
        "q"|"Q")
            exit 0
            ;;
        "n"|"N")
            show_action_menu "new"
            ;;
        "m"|"M")
            show_multi_site_menu "${sites[@]}"
            ;;
        *)
            if [[ $CHOICE =~ ^[0-9]+$ ]] && [ "$CHOICE" -le "${#sites[@]}" ] && [ "$CHOICE" -gt 0 ]; then
                show_single_site_menu "${sites[$CHOICE-1]}"
            else
                echo -e "${RED}Invalid selection. Please try again.${NC}"
                show_interactive_menu
            fi
            ;;
    esac
}



# Show the menu for specific actions
show_action_menu() {
    local action=$1
    shift
    local -a sites=("$@")

    case $action in
        "brand-new")
            while true; do
                read -p "Do you want to install new WordPress site now? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    show_action_menu "new"
                    return
                else
                    exit
                fi
            done
            ;;
        "new")
            while true; do
                read -p "Enter domain for new WordPress site (or 'q' to quit): " domain
                if [ "$domain" = "q" ]; then
                    show_interactive_menu
                    return
                fi
                if validate_domain "$domain"; then
                    install_site "$domain"
                    break
                fi
            done
            ;;
        "delete")
            echo -e "\n${YELLOW}Selected sites to delete:${NC}"
            printf '%s\n' "${sites[@]}"
            read -p "Are you sure you want to delete these sites? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                for site in "${sites[@]}"; do
                    delete_sites "$site"
                done
            else
                show_interactive_menu
            fi
            ;;
        "stop")
            echo -e "\n${YELLOW}Stopping selected sites:${NC}"
            printf '%s\n' "${sites[@]}"
            for site in "${sites[@]}"; do
                stop_sites "$site"
            done
            ;;
        "all")
            echo -e "\n${BLUE}Available actions for all sites:${NC}"
            echo "1) Stop all sites"
            echo "2) Delete all sites"
            echo "3) Back to main menu"
            read -p "Enter your choice: " choice
            case $choice in
                1) stop_sites "all" ;;
                2) delete_sites "all" ;;
                3) show_interactive_menu ;;
                *) echo -e "${RED}Invalid choice${NC}" ;;
            esac
            ;;
    esac
}

# Get the current status of a site

get_site_status() {
    local compose_file=$1
    local status=""
    local running_count=0
    local total_count=0
    
    # Get the total number of containers defined in the compose file
    total_count=$(docker compose -f "$compose_file" ps --quiet | wc -l)
    
    # Get the number of running containers
    running_count=$(docker compose -f "$compose_file" ps --status running --quiet | wc -l)
    
    if [ $total_count -eq 0 ]; then
        status="${YELLOW}[Not Started]${NC}"
    elif [ $running_count -eq 0 ]; then
        status="${RED}[Stopped]${NC}"
    elif [ $running_count -eq $total_count ]; then
        status="${GREEN}[Running]${NC}"
    else
        status="${YELLOW}[Partial: $running_count/$total_count]${NC}"
    fi
    
    echo -e "$status"
}


# Function to install a new WordPress site
install_site() {

    FIRST_TIME=false
    if ! check_container_running "caddy"; then
        FIRST_TIME=true
    fi

    setup_directories

    DOMAIN="$1"
    
    WP_PROJECT_DIR="${WORDPRESS_DIR}/${DOMAIN}"
    if [ -d "$WP_PROJECT_DIR" ]; then
        print_error "${RED}Directory ${WP_PROJECT_DIR} already exists!${NC}"
        exit 1
    fi

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
                        print_success "${GREEN}Complete setup finished successfully!${NC}"
                    else
                        print_error "${RED}WordPress setup failed. You may need to run setup manually later.${NC}"
                    fi
                else
                    print_error "${RED}Service startup failed. You may need to start services manually.${NC}"
                fi
                break
                ;;
            2)
                print_info "\n${BLUE}Manual setup instructions:${NC}"
                if [ "$FIRST_TIME" = true ]; then
                    print_info "1. Start Caddy:"
                    print_info "   cd ${CADDY_DIR} && docker compose up -d"
                fi
                reload_caddy
                print_info "2. Start WordPress:"
                print_info "   cd ${WP_PROJECT_DIR} && docker compose up -d"
                print_info "3. Run the WordPress setup script:"
                print_info "   ./wp-setup.sh"
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
list_sites_sss() {
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

list_sites() {
    print_subheader "Installed WordPress Sites"
    while IFS= read -r site; do
        if [ -f "$site/compose.yaml" ]; then
            sites+=("$(basename "$site")")
            domain=$(basename "$site")
            status=$(get_site_status "$site/compose.yaml")
            print_menu_item "$i" "$domain" "$status"
            ((i++))
        fi
    done < <(find "$WORDPRESS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

}


# Function to stop WordPress sites
stop_sites() {
    local target="$1"
    
    if [ ! -d "$WORDPRESS_DIR" ]; then
        echo "No WordPress installations found!"
        exit 1
    fi

    case "$target" in
        "all")
            echo "Stopping all WordPress containers..."
            # Stop Caddy first
            if [ -f "${CADDY_DIR}/compose.yaml" ]; then
                echo "Stopping Caddy reverse proxy..."
                docker compose -f "${CADDY_DIR}/compose.yaml" stop
            fi
            
            # Stop all WordPress installations
            for site in "$WORDPRESS_DIR"/*; do
                if [ -d "$site" ] && [ -f "$site/compose.yaml" ]; then
                    domain=$(basename "$site")
                    echo "Stopping site: $domain"
                    docker compose -f "$site/compose.yaml" stop
                fi
            done
            echo "All containers have been stopped."
            ;;
            
        *)
            # Stop specific site
            WP_PROJECT_DIR="${WORDPRESS_DIR}/${target}"
            if [ ! -d "$WP_PROJECT_DIR" ] || [ ! -f "$WP_PROJECT_DIR/compose.yaml" ]; then
                echo "Error: Site '$target' not found"
                exit 1
            fi
            echo "Stopping site: $target"
            docker compose -f "$WP_PROJECT_DIR/compose.yaml" stop
            echo "Site containers have been stopped."
            ;;
    esac
}

# Function to start WordPress sites
start_sites() {
    local target="$1"
    
    if [ ! -d "$WORDPRESS_DIR" ]; then
        echo "No WordPress installations found!"
        exit 1
    fi

    case "$target" in
        "all")
            echo "Starting all WordPress containers..."
            # Start Caddy first
            if [ -f "${CADDY_DIR}/compose.yaml" ]; then
                echo "Starting Caddy reverse proxy..."
                docker compose -f "${CADDY_DIR}/compose.yaml" up -d
            fi
            
            # Start all WordPress installations
            for site in "$WORDPRESS_DIR"/*; do
                if [ -d "$site" ] && [ -f "$site/compose.yaml" ]; then
                    domain=$(basename "$site")
                    echo "Starting site: $domain"
                    docker compose -f "$site/compose.yaml" up -d
                fi
            done
            echo "All containers have been started."
            ;;
            
        *)
            # Start specific site
            WP_PROJECT_DIR="${WORDPRESS_DIR}/${target}"
            if [ ! -d "$WP_PROJECT_DIR" ] || [ ! -f "$WP_PROJECT_DIR/compose.yaml" ]; then
                echo "Error: Site '$target' not found"
                exit 1
            fi
            echo "Starting site: $target"
            docker compose -f "$WP_PROJECT_DIR/compose.yaml" up -d
            echo "Site containers have been started."
            ;;
    esac
}

# Function to delete a WordPress site
delete_sites() {
    DOMAIN="$1"
    WP_PROJECT_DIR="${WORDPRESS_DIR}/${DOMAIN}"

    case "$DOMAIN" in
        "all")
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

                # Remove log files
                rm -rf kazewp.log

                docker system prune -af 

                echo "Uninstallation complete."
            else
                echo "Uninstallation aborted."
            fi
        ;;
        
        *)
            if [ ! -d "$WP_PROJECT_DIR" ]; then
                echo "Error: Site '$DOMAIN' not found"
                return 1
            else
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
            fi
        ;;
    esac

   
        
    
}


show_single_site_menu() {
    local domain=$1
    local compose_file="${WORDPRESS_DIR}/${domain}/compose.yaml"
    local status=$(get_site_status "$compose_file")
    
     while true; do
        print_header "Site Management"
        print_info "Managing site: ${BGREEN}${domain}${NC} ${status}"
        print_separator
        
        print_menu_item "1" "Start site"
        print_menu_item "2" "Stop site"
        print_menu_item "3" "Restart site"
        print_menu_item "4" "View site details"
        print_menu_item "5" "Delete site"
        print_menu_action "b" "Back to main menu"
        print_menu_action "q" "Quit"
        print_separator

        read -p "$(echo -e ${BCYAN}⮕${NC}) " action

        case $action in
            1)
                start_sites "$domain"
                status=$(get_site_status "$compose_file")
                ;;
            2)
                stop_sites "$domain"
                status=$(get_site_status "$compose_file")
                ;;
            3)
                restart_sites "$domain"
                status=$(get_site_status "$compose_file")
                ;;
            4)
                show_site_details "$domain"
                read -p "Press Enter to continue..."
                ;;
            5)
                delete_sites "$domain"
                show_interactive_menu
                return
                ;;
            "b"|"B")
                show_interactive_menu
                return
                ;;
            "q"|"Q")
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
    done
}

show_multi_site_menu() {
    local -a sites=("$@")
    
    print_header "Site Management"
    print_separator
    echo "Select sites (e.g., 1,3,5 or 1-4 or all):"
    
    local i=1
    for domain in "${sites[@]}"; do
        status=$(get_site_status "${WORDPRESS_DIR}/${domain}/compose.yaml")
        echo -e "$i) $domain ${status}"
        ((i++))
    done
    
    echo "----------------------------------------"
    read -p "Enter site selection (or 'b' for back): " selection
    
    [ "$selection" = "b" ] && show_interactive_menu && return
    
    if [ "$selection" = "all" ]; then
        selected_sites=("${sites[@]}")
    else
        # Convert selection to array of sites
        local -a selected_sites=()
        IFS=',' read -ra NUMS <<< "$selection"
        for num in "${NUMS[@]}"; do
            if [[ $num =~ ^[0-9]+-[0-9]+$ ]]; then
                # Handle range (e.g., "1-3")
                start="${num%-*}"
                end="${num#*-}"
                for ((i=start; i<=end; i++)); do
                    if [ $i -le ${#sites[@]} ]; then
                        selected_sites+=("${sites[$i-1]}")
                    fi
                done
            elif [[ $num =~ ^[0-9]+$ ]] && [ "$num" -le "${#sites[@]}" ]; then
                selected_sites+=("${sites[$num-1]}")
            fi
        done
    fi
    
    if [ ${#selected_sites[@]} -eq 0 ]; then
        echo -e "${RED}No valid sites selected${NC}"
        sleep 2
        show_multi_site_menu "${sites[@]}"
        return
    fi
    
    show_bulk_action_menu "${selected_sites[@]}"
}

show_bulk_action_menu() {
    local -a sites=("$@")
    
    echo -e "\n${BLUE}Bulk Actions for Selected Sites:${NC}"
    echo "Selected sites: ${sites[*]}"
    echo "----------------------------------------"
    echo "1) Start sites"
    echo "2) Stop sites"
    echo "3) Restart sites"
    echo "4) Delete sites"
    echo "b) Back to site selection"
    echo "q) Quit"
    echo "----------------------------------------"
    
    read -p "Enter your choice: " action
    
    case $action in
        1)
            for site in "${sites[@]}"; do
                start_sites "$site"
            done
            ;;
        2)
            for site in "${sites[@]}"; do
                stop_sites "$site"
            done
            ;;
        3)
            for site in "${sites[@]}"; do
                restart_sites "$site"
            done
            ;;
        4)
            echo -e "${YELLOW}Are you sure you want to delete these sites?${NC}"
            printf '%s\n' "${sites[@]}"
            read -p "Confirm deletion (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                for site in "${sites[@]}"; do
                    delete_sites "$site"
                done
            fi
            show_interactive_menu
            return
            ;;
        "b"|"B")
            show_multi_site_menu "${sites[@]}"
            return
            ;;
        "q"|"Q")
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 2
            show_bulk_action_menu "${sites[@]}"
            ;;
    esac
    
    show_multi_site_menu "${sites[@]}"
}

show_site_details() {
    local domain=$1
    local compose_file="${WORDPRESS_DIR}/${domain}/compose.yaml"
    
    echo -e "\n${BLUE}Site Details for ${GREEN}${domain}${NC}"
    echo "----------------------------------------"
    echo -e "Status: $(get_site_status "$compose_file")"
    echo "Installation Directory: ${WORDPRESS_DIR}/${domain}"
    echo -e "\nContainer Status:"
    docker compose -f "$compose_file" ps
    #echo -e "\nContainer Logs (last 5 lines):"
    #docker compose -f "$compose_file" logs --tail=5
}


restart_sites() {
    local domain=$1
    echo -e "${YELLOW}Restarting site: ${domain}${NC}"
    docker compose -f "${WORDPRESS_DIR}/${domain}/compose.yaml" restart
}