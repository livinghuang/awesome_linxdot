#!/bin/sh

# Linxdot OpenSource:
# Purpose: Call the chirpstack-gateway-mesh runtime in the background.
# Author: Living Huang
# Date: 2025-02-23

# Default region or user-provided parameter
region="${1:-as923}"
echo "Using region: $region"
logger -t "chirpstack-gateway-mesh" "Starting with region: $region"

# Directories and executables
base_dir="/opt/awesome_linxdot/chirpstack-software/chirpstack-gateway-mesh-binary"
executable="$base_dir/chirpstack-gateway-mesh"
config_dir="$base_dir/config"
main_config="$config_dir/chirpstack-gateway-mesh.toml"
region_config="$config_dir/region_$region.toml"

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

# Trap for graceful shutdown
trap 'echo "Stopping chirpstack-gateway-mesh..."; logger -t "chirpstack-gateway-mesh" "Service stopped."; exit 0' INT TERM

# Change to the base directory
cd "$base_dir" || exit 1

# Main loop
while true; do
    echo "Launching chirpstack-gateway-mesh..."
    logger -t "chirpstack-gateway-mesh" "Launching process with region: $region"

    "$executable" -c "$main_config" -c "$region_config" | logger -t "chirpstack-gateway-mesh"

    echo "Process exited unexpectedly. Restarting in 5 seconds..."
    logger -t "chirpstack-gateway-mesh" "Process exited unexpectedly. Restarting after 5 seconds."
    sleep 5
done

exit 0
