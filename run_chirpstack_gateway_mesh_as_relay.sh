#!/bin/sh

# Linxdot OpenSource:
# Purpose: Run the chirpstack-gateway-mesh-as-relay in the background with continuous monitoring.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Added PID check, process termination, improved logging, and robust error handling.

# Default region or user-provided parameter
region="${1:-as923}"
echo "Using region: $region"
logger -t "chirpstack-gateway-mesh" "Service starting with region: $region"

# Directories and executables
base_dir="/opt/awesome_linxdot/chirpstack-software/chirpstack-gateway-mesh-binary"
executable="$base_dir/chirpstack-gateway-mesh"
config_dir="$base_dir/config"
main_config="$config_dir/chirpstack-gateway-mesh-as-relay.toml"
region_config="$config_dir/region_$region.toml"
channels_config="$config_dir/channels_$region.toml"

# --- Pre-run Checks ---

# Check if working directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory $base_dir does not exist."
    logger -t "chirpstack-gateway-mesh" "Error: Directory $base_dir not found."
    exit 1
fi

# Check if executable exists and is executable
if [ ! -x "$executable" ]; then
    echo "Error: Executable $executable not found or not executable."
    logger -t "chirpstack-gateway-mesh" "Error: Executable not found or not executable."
    exit 1
fi

# Check if config files exist
for config_file in "$main_config" "$region_config"; do
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file $config_file not found."
        logger -t "chirpstack-gateway-mesh" "Error: Missing config file: $config_file"
        exit 1
    fi
done

# --- Process Management ---

# Check if the process is already running
existing_pid=$(pgrep -f "$executable")
if [ -n "$existing_pid" ]; then
    echo "Found existing process (PID: $existing_pid). Attempting to stop it..."
    logger -t "chirpstack-gateway-mesh" "Existing process detected (PID: $existing_pid). Attempting to stop it."

    kill "$existing_pid"

    # Wait until the process terminates (up to 10 seconds)
    timeout=10
    while ps -p "$existing_pid" >/dev/null 2>&1 && [ "$timeout" -gt 0 ]; do
        echo "Waiting for process $existing_pid to stop... ($timeout seconds left)"
        sleep 1
        timeout=$((timeout - 1))
    done

    # Check if termination was successful
    if ps -p "$existing_pid" >/dev/null 2>&1; then
        echo "Failed to stop process $existing_pid. Aborting startup."
        logger -t "chirpstack-gateway-mesh" "Error: Could not terminate existing process (PID: $existing_pid)."
        exit 1
    fi

    echo "Previous process stopped successfully."
    logger -t "chirpstack-gateway-mesh" "Existing process stopped successfully."
fi

# --- Signal Handling ---

# Handle termination signals for graceful shutdown
trap 'echo "Stopping chirpstack-gateway-mesh..."; logger -t "chirpstack-gateway-mesh" "Service stopped."; exit 0' INT TERM

# --- Main Loop ---

cd "$base_dir" || exit 1

while true; do
    echo "Launching chirpstack-gateway-mesh with region: $region..."
    logger -t "chirpstack-gateway-mesh" "Launching process with region: $region"

    "$executable" -c "$main_config" -c "$region_config" -c "$channels_config" | logger -t "chirpstack-gateway-mesh"

    echo "Process exited unexpectedly. Restarting in 5 seconds..."
    logger -t "chirpstack-gateway-mesh" "Process exited unexpectedly. Restarting after 5 seconds."
    sleep 5
done

exit 0
