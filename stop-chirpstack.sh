#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop the ChirpStack service using docker-compose.
# Author: Living Huang
# Date: 2025-02-23

# Variables
system_dir="/opt/awesome_linxdot/chirpstack-software/chirpstack-docker"

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

echo "Step 2: ChirpStack stop process completed."
