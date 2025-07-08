#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop the ChirpStack service using docker-compose and remove init.d service.
# Author: Living Huang
# Date: 2025-07-08

# Variables
system_dir="/opt/awesome_linxdot/awesome_software/chirpstack_server/chirpstack_docker"
init_script="/etc/init.d/linxdot_chirpstack_service"

echo "Step 1: Stopping ChirpStack service using docker-compose..."

# Check if the Docker Compose directory exists
if [ ! -d "$system_dir" ]; then
    echo "Error: Directory $system_dir does not exist."
    logger -t "chirpstack" "Error: Directory $system_dir not found. Cannot stop ChirpStack."
    exit 1
fi

# Navigate to the directory and stop services
cd "$system_dir" || {
    echo "Error: Failed to change directory to $system_dir."
    logger -t "chirpstack" "Error: Failed to change directory."
    exit 1
}

if docker-compose down; then
    echo "ChirpStack services stopped successfully."
    logger -t "chirpstack" "ChirpStack services stopped via docker-compose."
else
    echo "Error: Failed to stop ChirpStack services."
    logger -t "chirpstack" "Error: docker-compose down failed."
    exit 1
fi

echo "Step 2: Stopping and removing init.d service script..."

# Check if the init.d script exists
if [ -f "$init_script" ]; then
    # Stop the init.d service before removal
    if "$init_script" stop; then
        echo "Init.d service stopped successfully."
        logger -t "chirpstack" "Init.d service stopped."
    else
        echo "Warning: Failed to stop init.d service. Proceeding with removal."
        logger -t "chirpstack" "Warning: Failed to stop init.d service."
    fi

    # Remove the init.d script
    if rm "$init_script"; then
        echo "Init.d service script removed successfully."
        logger -t "chirpstack" "Init.d service script $init_script removed."
    else
        echo "Error: Failed to remove $init_script."
        logger -t "chirpstack" "Error: Failed to remove $init_script."
        exit 1
    fi
else
    echo "Warning: Init.d service script $init_script does not exist."
    logger -t "chirpstack" "Warning: $init_script not found."
fi

echo "Step 3: ChirpStack stop process completed."
