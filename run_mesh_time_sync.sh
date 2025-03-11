#!/bin/sh

# Set base directory
base_dir="/opt/awesome_linxdot/awesome-software/mesh_relay_time_sync"
executable="$base_dir/mesh_relay_time_sync"
log_file="/tmp/mesh_relay_time_sync.log"
pid_file="/tmp/mesh_relay_time_sync.pid"

while true; do
    # Change to base directory
    cd "$base_dir" || exit 1

    # Check if the process is already running
    if [ -f "$pid_file" ]; then
        old_pid=$(cat "$pid_file")
        if [ -d "/proc/$old_pid" ]; then
            logger -t "mesh_relay_time_sync" "Process already running (PID: $old_pid), skipping restart."
            sleep 300
            continue
        fi
    fi

    # Start the process and store its PID
    "$executable" > "$log_file" 2>&1 &
    new_pid=$!
    echo "$new_pid" > "$pid_file"
    
    logger -t "mesh_relay_time_sync" "Process started (PID: $new_pid). Logs: $log_file"

    # Limit log file size (keep only the last 100KB)
    tail -c 100000 "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"

    # Wait before the next check
    sleep 300
done

exit 0
