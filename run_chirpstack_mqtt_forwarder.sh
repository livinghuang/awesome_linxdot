#!/bin/sh

# Linxdot OpenSource:
# Purpose: Run the chirpstack-mqtt-forwarder in the background with continuous monitoring.
# Author: Living Huang
# Date: 2025-02-23

echo "Starting chirpstack-mqtt-forwarder..."
logger -t "chirpstack-mqtt-forwarder" "Service starting..."

# Directories and executable
base_dir="/opt/awesome_linxdot/chirpstack-software/chirpstack-mqtt-forwarder-binary"
executable="$base_dir/chirpstack-mqtt-forwarder"
config_file="$base_dir/chirpstack-mqtt-forwarder.toml"

# Check if the working directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory $base_dir does not exist."
    logger -t "chirpstack-mqtt-forwarder" "Error: Directory $base_dir not found."
    exit 1
fi

# Check if the executable exists and is executable
if [ ! -x "$executable" ]; then
    echo "Error: Executable $executable not found or not executable."
    logger -t "chirpstack-mqtt-forwarder" "Error: Executable not found or not executable."
    exit 1
fi

# Check if the configuration file exists
if [ ! -f "$config_file" ]; then
    echo "Error: Configuration file $config_file not found."
    logger -t "chirpstack-mqtt-forwarder" "Error: Configuration file not found."
    exit 1
fi

# Handle termination signals for a graceful shutdown
trap 'echo "Stopping chirpstack-mqtt-forwarder..."; logger -t "chirpstack-mqtt-forwarder" "Service stopped."; exit 0' INT TERM

# Main loop to keep the service running
cd "$base_dir" || exit 1

while true; do
    echo "Launching chirpstack-mqtt-forwarder..."
    logger -t "chirpstack-mqtt-forwarder" "Launching forwarder process."

    "$executable" -c "$config_file" | logger -t "chirpstack-mqtt-forwarder"

    echo "Forwarder process exited. Restarting in 5 seconds..."
    logger -t "chirpstack-mqtt-forwarder" "Process exited unexpectedly. Restarting after 5 seconds."
    sleep 5
done

exit 0
