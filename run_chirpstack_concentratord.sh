#!/bin/sh

# Linxdot OpenSource:
# Purpose: Call the lora_pkt_fwd runtime in the background.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Added PID check and process termination before start.

# Default region handling
region="${1:-as923}"
echo "Using region: $region"
logger -t "chirpstack-concentratord" "Starting with region: $region"

# Directories and executable
base_dir="/opt/awesome_linxdot/chirpstack-software/chirpstack-concentratord-binary"
executable="$base_dir/chirpstack-concentratord-sx1302"

# Config files
config_dir="$base_dir/config"
concentratord_config="$config_dir/concentratord.toml"
channels_config="$config_dir/channels_$region.toml"
region_config="$config_dir/region_$region.toml"

# Check directory existence
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory $base_dir does not exist."
    logger -t "chirpstack-concentratord" "Error: Directory not found."
    exit 1
fi

# Check executable
if [ ! -x "$executable" ]; then
    echo "Error: Executable $executable not found or not executable."
    logger -t "chirpstack-concentratord" "Error: Executable not found or not executable."
    exit 1
fi

# Check configuration files
for config_file in "$concentratord_config" "$channels_config" "$region_config"; do
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file $config_file not found."
        logger -t "chirpstack-concentratord" "Error: Missing config file: $config_file"
        exit 1
    fi
done

# Check if the concentratord process is already running
existing_pid=$(pgrep -f "$executable")
if [ -n "$existing_pid" ]; then
    echo "Found existing process (PID: $existing_pid). Stopping it..."
    logger -t "chirpstack-concentratord" "Existing process detected (PID: $existing_pid). Attempting to stop it."
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
        logger -t "chirpstack-concentratord" "Error: Could not terminate existing process (PID: $existing_pid)."
        exit 1
    fi

    echo "Previous process stopped successfully."
    logger -t "chirpstack-concentratord" "Existing process stopped successfully."
fi

# Handle graceful shutdown
trap 'echo "Stopping ChirpStack Concentratord..."; logger -t "chirpstack-concentratord" "Service stopped."; exit 0' INT TERM

# Run the concentratord in an infinite loop
cd "$base_dir" || exit 1

while true; do
    echo "Launching ChirpStack Concentratord..."
    logger -t "chirpstack-concentratord" "Launching concentratord process."

    "$executable" \
        -c "$concentratord_config" \
        -c "$channels_config" \
        -c "$region_config" | logger -t "chirpstack-concentratord"

    echo "ChirpStack Concentratord exited unexpectedly. Restarting in 5 seconds..."
    logger -t "chirpstack-concentratord" "Process exited. Restarting after 5 seconds."
    sleep 5
done

exit 0
