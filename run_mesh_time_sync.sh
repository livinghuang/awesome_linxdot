#!/bin/sh

# Linxdot OpenSource:
# Purpose: Run mesh_time_sync in the background.
# Author: Living Huang
# Date: 2025-03-11
# Updated: Redirect logs to OpenWrt logger instead of a log file.

# Directories and executable
base_dir="/opt/awesome_linxdot/awesome-software/mesh_time_sync"
executable="$base_dir/mesh_time_sync"

# Check directory existence
if [ ! -d "$base_dir" ]; then
    logger -t "mesh_time_sync" "Error: Directory $base_dir does not exist."
    exit 1
fi

# Check executable
if [ ! -x "$executable" ]; then
    logger -t "mesh_time_sync" "Error: Executable $executable not found or not executable."
    exit 1
fi

# Check if the process is already running
existing_pid=$(pgrep -f "$executable")
if [ -n "$existing_pid" ]; then
    logger -t "mesh_time_sync" "Existing process detected (PID: $existing_pid). Stopping it."
    kill "$existing_pid"

    # Wait for process termination
    timeout=10
    while ps -p "$existing_pid" >/dev/null 2>&1 && [ "$timeout" -gt 0 ]; do
        sleep 1
        timeout=$((timeout - 1))
    done

    if ps -p "$existing_pid" >/dev/null 2>&1; then
        logger -t "mesh_time_sync" "Error: Could not terminate existing process (PID: $existing_pid)."
        exit 1
    fi

    logger -t "mesh_time_sync" "Previous process stopped successfully."
fi

# Handle graceful shutdown
trap 'logger -t "mesh_time_sync" "Service stopped."; exit 0' INT TERM

# Run the process in an infinite loop and send logs to logger
cd "$base_dir" || exit 1

(
    while true; do
        if pgrep -f "$executable" > /dev/null; then
            logger -t "mesh_time_sync" "Process is already running. No restart needed."
            sleep 60
            continue
        fi

        logger -t "mesh_time_sync" "Launching mesh_time_sync process."

        "$executable" 2>&1 | logger -t "mesh_time_sync"

        logger -t "mesh_time_sync" "Process exited unexpectedly. Restarting after 60 seconds."
        sleep 60
    done
) | logger -t mesh_time_sync &
