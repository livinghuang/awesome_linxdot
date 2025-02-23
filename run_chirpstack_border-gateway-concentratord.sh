#!/bin/sh

# Linxdot OpenSource:
# Purpose: Call the lora_pkt_fwd runtime in the background.
# Author: Living Huang
# Date: 2025-02-23

# Set default region
region=${1:-"as923"}

echo "ChirpStack Concentratord starting with region: $region"
logger -t "chirpstack-border-concentratord" "Starting with region: $region"

concentratord_dir="/opt/awesome_linxdot/chirpstack-border-gateway/chirpstack-concentratord-binary"
executable="$concentratord_dir/chirpstack-concentratord-sx1302"

# Verify directory exists
if [ ! -d "$concentratord_dir" ]; then
    echo "Error: Directory $concentratord_dir does not exist."
    logger -t "chirpstack-border-concentratord" "Error: Directory $concentratord_dir not found."
    exit 1
fi

# Verify the executable exists and is executable
if [ ! -x "$executable" ]; then
    echo "Error: Executable $executable not found or not executable."
    logger -t "chirpstack-border-concentratord" "Error: Executable $executable not found or not executable."
    exit 1
fi

# Configuration files
config_dir="$concentratord_dir/config"
concentratord_config="$config_dir/concentratord.toml"
channels_config="$config_dir/channels_$region.toml"
region_config="$config_dir/region_$region.toml"

# Verify all config files exist
for config in "$concentratord_config" "$channels_config" "$region_config"; do
    if [ ! -f "$config" ]; then
        echo "Error: Config file $config not found."
        logger -t "chirpstack-border-concentratord" "Error: Config file $config not found."
        exit 1
    fi
done

# Trap to handle termination signals
trap 'echo "Stopping ChirpStack Concentratord..."; logger -t "chirpstack-border-concentratord" "Service stopped."; exit 0' INT TERM

# Main loop
cd "$concentratord_dir" || exit 1

while true; do
    echo "Launching ChirpStack Concentratord..."
    logger -t "chirpstack-border-concentratord" "Launching concentratord process."

    "$executable" \
        -c "$concentratord_config" \
        -c "$channels_config" \
        -c "$region_config" | logger -t "chirpstack-border-concentratord"

    echo "ChirpStack Concentratord process exited. Restarting in 5 seconds..."
    logger -t "chirpstack-border-concentratord" "Process exited. Restarting after 5 seconds."
    sleep 5
done

exit 0
