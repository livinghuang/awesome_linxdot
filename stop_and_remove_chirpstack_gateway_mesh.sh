#!/bin/sh

# Linxdot OpenSource:
# Purpose: Uninstall the chirpstack-gateway-mesh service, kill related processes, and clean up.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Unified into a single service removal with complete process and file cleanup.


process_name="chirpstack-gateway-mesh"
service_name="linxdot-chirpstack-gateway-mesh"
service_file="/etc/init.d/${service_name}"
pid_file="/var/run/${process_name}.pid"
lock_file="/tmp/${process_name}.lock"

echo "Step 1: Stopping and disabling service..."

if [ -f "$service_file" ]; then
    echo "Stopping service: $service_name..."
    "$service_file" stop || true
    sleep 2

    echo "Disabling service: $service_name..."
    "$service_file" disable || true

    echo "Removing service file: $service_file..."
    rm -f "$service_file"
else
    echo "No service file found for $service_name. Skipping."
fi

echo "Step 2: Killing all running processes related to $process_name..."

pids=$(pgrep -f "$process_name")
if [ -n "$pids" ]; then
    echo "Found running processes: $pids. Attempting to kill..."
    for pid in $pids; do
        kill "$pid" && echo "Killed PID $pid" || echo "Failed to kill PID $pid"
    done

    sleep 2

    # Force kill if any process remains
    remaining_pids=$(pgrep -f "$process_name")
    if [ -n "$remaining_pids" ]; then
        echo "Force killing remaining processes: $remaining_pids..."
        for pid in $remaining_pids; do
            kill -9 "$pid" && echo "Force killed PID $pid" || echo "Failed to force kill PID $pid"
        done
    else
        echo "No remaining processes found."
    fi
else
    echo "No running processes found."
fi

echo "Step 3: Cleaning up temporary files..."

if [ -f "$pid_file" ]; then
    rm -f "$pid_file"
    echo "PID file removed."
fi

if [ -f "$lock_file" ]; then
    rm -f "$lock_file"
    echo "Lock file removed."
fi

echo "Step 4: Uninstallation completed. All related services and processes have been removed."
sed -i '/run_mesh_time_sync.sh/d' /etc/crontabs/root
/etc/init.d/cron restart
logger -t "chirpstack-gateway-mesh" "Cron job for mesh relay time sync removed."

echo "Step 5: Uninstallation completed. All related services and processes have been removed."
