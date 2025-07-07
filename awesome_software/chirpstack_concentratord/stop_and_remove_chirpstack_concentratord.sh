#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the ChirpStack Concentratord service.

set -e  # Exit immediately if any command fails

service_file="/etc/init.d/linxdot_chirpstack_concentratord"
process_name="chirpstack_concentratord_sx1302"

echo "Step 1: Attempting to stop ChirpStack Concentratord via init.d service..."
logger -t "$process_name" "Attempting to stop service."

# Stop the service if it exists
if [ -f "$service_file" ]; then
    "$service_file" stop || true
    echo "Service stop command issued."
    logger -t "$process_name" "Service stop command issued."
    sleep 2  # Allow time for shutdown
else
    echo "Warning: Service file not found. Skipping service stop."
    logger -t "$process_name" "Service file not found. Skipping stop."
fi

echo "Step 2: Checking for lingering processes..."
# Find all PIDs related to the process name, excluding the grep process and this script itself
pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')

if [ -n "$pids" ]; then
    echo "Found process PID(s): $pids. Attempting to terminate..."
    logger -t "$process_name" "Terminating PID(s): $pids."

    # Kill all matched processes
    for pid in $pids; do
        kill "$pid" && echo "Terminated PID $pid" || echo "Failed to terminate PID $pid"
    done

    sleep 2

    # Check if any processes are still running and force kill them
    remaining_pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')
    if [ -n "$remaining_pids" ]; then
        echo "Force killing remaining PID(s): $remaining_pids..."
        logger -t "$process_name" "Force killing PID(s): $remaining_pids."
        for pid in $remaining_pids; do
            kill -9 "$pid" && echo "Force killed PID $pid" || echo "Failed to force kill PID $pid"
        done
    else
        echo "All processes terminated successfully."
        logger -t "$process_name" "All processes terminated successfully."
    fi
else
    echo "No running process found for $process_name."
    logger -t "$process_name" "No running process found."
fi

echo "Step 3: Disabling service autostart..."
if [ -f "$service_file" ]; then
    "$service_file" disable
    echo "Service disabled from startup."
    logger -t "$process_name" "Service disabled."
else
    echo "Service file not found. Skipping disable step."
    logger -t "$process_name" "No service file to disable."
fi

echo "Step 4: Removing service file..."
if [ -f "$service_file" ]; then
    rm -f "$service_file"
    echo "Service file removed from /etc/init.d/."
    logger -t "$process_name" "Service file removed."
else
    echo "No service file found to remove."
    logger -t "$process_name" "No service file to remove."
fi

echo "Step 5: ChirpStack Concentratord stop and removal process completed."
logger -t "$process_name" "Stop and removal completed."
