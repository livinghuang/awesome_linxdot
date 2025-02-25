#!/bin/sh

# Linxdot OpenSource:
# Purpose: Run the chirpstack-mqtt-forwarder in the background with continuous monitoring.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Combined script to handle multiple configuration files via parameter.

# --- Input Parameters ---

# Usage: ./run_chirpstack_mqtt_forwarder.sh <config_file>
config_file="${1:-chirpstack-mqtt-forwarder.toml}"

echo "Starting chirpstack-mqtt-forwarder with configuration: $config_file"
logger -t "chirpstack-mqtt-forwarder" "Service starting with configuration: $config_file"

# --- Directories and Executables ---

base_dir="/opt/awesome_linxdot/chirpstack-software/chirpstack-mqtt-forwarder-binary"
executable="$base_dir/chirpstack-mqtt-forwarder"
config_path="$base_dir/$config_file"

# --- Pre-run Checks ---

# Check if working directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory $base_dir does not exist."
    logger -t "chirpstack-mqtt-forwarder" "Error: Directory $base_dir not found."
    exit 1
fi

# Check if executable exists and is executable
if [ ! -x "$executable" ]; then
    echo "Error: Executable $executable not found or not executable."
    logger -t "chirpstack-mqtt-forwarder" "Error: Executable not found or not executable."
    exit 1
fi

# Check if configuration file exists
if [ ! -f "$config_path" ]; then
    echo "Error: Configuration file $config_path not found."
    logger -t "chirpstack-mqtt-forwarder" "Error: Configuration file $config_path not found."
    exit 1
fi

# --- Process Management ---

# Check if the chirpstack-mqtt-forwarder process with the same config is already running
existing_pid=$(pgrep -f "$executable -c $config_path")
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

# --- Signal Handling ---

trap 'echo "Stopping chirpstack-mqtt-forwarder..."; logger -t "chirpstack-mqtt-forwarder" "Service stopped."; exit 0' INT TERM

# --- Main Execution Loop ---

cd "$base_dir" || exit 1

while true; do
    echo "Launching chirpstack-mqtt-forwarder with $config_file..."
    logger -t "chirpstack-mqtt-forwarder" "Launching process with configuration: $config_file"

    "$executable" -c "$config_path" | logger -t "chirpstack-mqtt-forwarder"

    echo "Process exited unexpectedly. Restarting in 5 seconds..."
    logger -t "chirpstack-mqtt-forwarder" "Process exited unexpectedly. Restarting after 5 seconds."
    sleep 5
done

exit 0
