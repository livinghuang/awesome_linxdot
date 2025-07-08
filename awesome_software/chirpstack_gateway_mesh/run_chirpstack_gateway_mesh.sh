#!/bin/sh

# Linxdot OpenSource:
# Purpose: Run the chirpstack_gateway_mesh in either 'as-border' or 'as-relay' mode with continuous monitoring.
# Author: Living Huang
# Date: 2025-07-08
# Updated: Added role parameter for flexibility between as-border and as-relay configurations.

# --- User Input and Defaults ---

# Parameters:
#   $1: Role (border or relay) - Default: border
#   $2: Region (e.g., as923) - Default: as923
role="${1:_border}"
region="${2:_as923}"

# Validate role
if [ "$role" != "border" ] && [ "$role" != "relay" ]; then
    echo "Error: Invalid role '$role'. Use 'border' or 'relay'."
    exit 1
fi

echo "Using role: $role | Using region: $region"
logger -t "chirpstack_gateway_mesh_as_$role" "Service starting with role: $role and region: $region"

# --- Directories and Files ---

base_dir="/opt/awesome_linxdot/chirpstack_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary"
executable="$base_dir/chirpstack_gateway_mesh_border_beacon" # chirpstack_gateway_mesh_border_beacon is revised version to send beacon from border to relay
config_dir="$base_dir/config"
channels_config="$config_dir/channels_${region}.toml"
region_config="$config_dir/region_${region}.toml"
main_config="$config_dir/chirpstack_gateway_mesh_as_${role}.toml"

# --- Pre-run Checks ---

if [ ! -d "$base_dir" ]; then
    echo "Error: Directory $base_dir does not exist."
    logger -t "chirpstack_gateway_mesh" "Error: Directory $base_dir not found."
    exit 1
fi

if [ ! -x "$executable" ]; then
    echo "Error: Executable $executable not found or not executable."
    logger -t "chirpstack_gateway_mesh" "Error: Executable not found or not executable."
    exit 1
fi

for config_file in "$channels_config" "$region_config" "$main_config"; do
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file $config_file not found."
        logger -t "chirpstack_gateway_mesh" "Error: Missing config file: $config_file"
        exit 1
    fi
done

# --- Process Management ---

existing_pid=$(pgrep -f "$executable.*$main_config")
if [ -n "$existing_pid" ]; then
    echo "Existing process found (PID: $existing_pid). Attempting to stop..."
    logger -t "chirpstack_gateway_mesh" "Stopping existing process (PID: $existing_pid)..."
    kill "$existing_pid"

    timeout=10
    while ps -p "$existing_pid" >/dev/null 2>&1 && [ "$timeout" -gt 0 ]; do
        echo "Waiting for process $existing_pid to stop... ($timeout seconds left)"
        sleep 1
        timeout=$((timeout - 1))
    done

    if ps -p "$existing_pid" >/dev/null 2>&1; then
        echo "Failed to stop process $existing_pid. Aborting."
        logger -t "chirpstack_gateway_mesh" "Error: Failed to stop existing process (PID: $existing_pid)."
        exit 1
    fi

    echo "Existing process stopped."
    logger -t "chirpstack_gateway_mesh" "Existing process stopped successfully."
fi

# --- Signal Handling ---

trap 'echo "Stopping chirpstack_gateway_mesh..."; logger -t "chirpstack_gateway_mesh" "Service stopped."; exit 0' INT TERM

# --- Main Execution Loop ---

cd "$base_dir" || exit 1

while true; do
    echo "Launching chirpstack_gateway_mesh as $role with region: $region..."
    logger -t "chirpstack_gateway_mesh" "Launching process as $role with region: $region"

    "$executable" -c "$channels_config" -c "$region_config" -c "$main_config" | logger -t "chirpstack_gateway_mesh"

    echo "Process exited unexpectedly. Restarting in 5 seconds..."
    logger -t "chirpstack_gateway_mesh" "Process exited unexpectedly. Restarting after 5 seconds."
    sleep 5
done

exit 0
