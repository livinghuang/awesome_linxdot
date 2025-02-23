#!/bin/sh

# Linxdot OpenSource:
# Purpose: Run the chirpstack-mqtt-forwarder in the background with continuous monitoring.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Added PID check, process termination, and improved logging.

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

# Check if the chirpstack-mqtt-forwarder process is already running
existing_pid=$(pgrep -f "$executable")
if [ -n "$existing_pid" ]; then
    echo "Found existing process (PID: $existing_pid). Stopping it..."
    logger -t "chirpstack-mqtt-forwarder" "Existing process detected (PID: $existing_pid). Attempting to stop it."
    kill "$existing_pid"

    # Wait until the process terminates
    timeout=10
    while ps -p "$existing_pid" >/dev/null 2>&1 && [ "$timeout" -gt 0 ]; do
        echo "Waiting for process $existing_pid to stop... ($timeout seconds left)"
        sleep 1
        timeout=$((timeout - 1))
    done

    if ps -p "$existing_pid" >/dev/null 2>&1; then
        echo "Failed to stop process $existing_pid. Aborting startup."
        logger -t "chirpstack-mqtt-forwarder" "Error: Could not terminate existing process (PID: $existing_pid)."
        exit 1
    fi

    echo "Previous process stopped successfully."
    logger -t "chirpstack-mqtt-forwarder" "Existing process stopped successfully."
fi

# Handle termination signals for a graceful shutdown
trap 'echo "Stopping chirpstack-mqtt-forwarder..."; logger -t "chirpstack-mqtt-forwarder" "Service stopped."; exit 0' INT TERM

# Main loop to keep the service running
cd "$base_dir" || exit 1

while true; do
    echo "Launching chirpstack-mqtt-forwarder..."
    logger -t "chirpstack-mqtt-forwarder" "Launching forwarder process."

    "$executable" -c "$config_file" | logger -t "chirpstack-mqtt-forwarder"

    echo "Forwarder process exited unexpectedly. Restarting in 5 seconds..."
    logger -t "chirpstack-mqtt-forwarder" "Process exited unexpectedly. Restarting after 5 seconds."
    sleep 5
done

exit 0
