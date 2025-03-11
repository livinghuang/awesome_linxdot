#!/bin/sh

# Set base directory
base_dir="/opt/awesome_linxdot/awesome-software/mesh_relay_time_sync"
executable="$base_dir/mesh_relay_time_sync"
log_file="/tmp/mesh_relay_time_sync.log"

while true; do
    # Change to base directory
    cd "$base_dir" || exit 1

    # Start process in the background and log output
    "$executable" > "$log_file" 2>&1 &
    sleep 300
done

# Log message to system logger
logger -t "mesh_relay_time_sync" "Process started. Logs: $log_file"
