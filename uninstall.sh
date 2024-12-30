#!/bin/bash

# Ask for confirmation before proceeding with the uninstallation
read -p "Are you sure you want to uninstall everything? This will stop and remove all containers, and delete files. (y/n): " confirm

if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    # Stop all running containers
    echo "Stopping all containers..."
    docker stop $(docker ps -a -q)

    # Remove all containers
    echo "Removing all containers..."
    docker rm $(docker ps -a -q)

    # Remove WordPress files
    echo "Removing WordPress files..."
    rm -rf wordpress

    # Remove Caddy files
    echo "Removing Caddy files..."
    rm -rf caddy

    echo "Uninstallation complete."
else
    echo "Uninstallation aborted."
fi
