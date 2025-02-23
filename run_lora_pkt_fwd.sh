#!/bin/sh

# Linxdot OpenSource:
# Purpose: Call the lora_pkt_fwd runtime in the background and control LED indicators.
# Author: Living Huang
# Date: 2025-02-23

# Default region handling
region="${1:-AS923_1}"

echo "Starting lora_pkt_fwd with region: $region"
logger -t "lora_pkt_fwd" "Starting with region: $region"

# Paths and executables
base_dir="/etc/lora"
config_file="$base_dir/global_conf.json.sx1250.$region"
log_file="/var/log/lora_pkt_fwd.log"
executable="lora_pkt_fwd"

# LED paths
led1="/sys/devices/platform/leds/leds/work-led1/brightness"
led2="/sys/devices/platform/leds/leds/work-led2/brightness"

# Check if base directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory $base_dir does not exist."
    logger -t "lora_pkt_fwd" "Error: Directory $base_dir not found."
    exit 1
fi

# Check if the configuration file exists
if [ ! -f "$config_file" ]; then
    echo "Error: Configuration file $config_file not found."
    logger -t "lora_pkt_fwd" "Error: Config file not found."
    exit 1
fi

# Check if the executable is available in PATH
if ! command -v "$executable" >/dev/null 2>&1; then
    echo "Error: Executable $executable not found."
    logger -t "lora_pkt_fwd" "Error: Executable $executable not found."
    exit 1
fi

# Trap for graceful shutdown
cleanup() {
    echo "Stopping lora_pkt_fwd and turning off LEDs..."
    logger -t "lora_pkt_fwd" "Service stopping..."
    [ -w "$led1" ] && echo 0 > "$led1"
    [ -w "$led2" ] && echo 0 > "$led2"
    pkill -f "$executable"
    exit 0
}
trap cleanup INT TERM

# Start lora_pkt_fwd in the background
cd "$base_dir" || exit 1
"$executable" -c "$config_file" > "$log_file" 2>&1 &
logger -t "lora_pkt_fwd" "Process started. Logs: $log_file"

# LED blinking loop
echo "Starting LED indication loop..."
while true; do
    [ -w "$led1" ] && echo 1 > "$led1"
    [ -w "$led2" ] && echo 1 > "$led2"
    sleep 1

    [ -w "$led1" ] && echo 0 > "$led1"
    [ -w "$led2" ] && echo 1 > "$led2"
    sleep 1
done

exit 0
