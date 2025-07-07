#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the chirpstack-mqtt-forwarder service.

set -e  # Exit immediately if a command exits with a non-zero status

service_file="/etc/init.d/linxdot-chirpstack-mqtt-forwarder"
process_name="chirpstack-mqtt-forwarder"

echo "Step 1: Attempting to stop via init.d service..."
logger -t "$process_name" "Attempting to stop service."

if [ -f "$service_file" ]; then
    "$service_file" stop || true
    echo "Service stop issued."
    logger -t "$process_name" "Service stop issued."
    sleep 2
else
    echo "Service file not found, proceeding..."
    logger -t "$process_name" "No service file found."
fi

echo "Step 2: Killing all running processes..."
# Find process IDs (PIDs) related to the process name
pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')

if [ -n "$pids" ]; then
    echo "Found PIDs: $pids. Attempting to kill..."
    logger -t "$process_name" "Killing PIDs: $pids"
    for pid in $pids; do
        kill "$pid" && echo "Killed PID $pid" || echo "Failed to kill PID $pid"
    done

    sleep 2

    # Check for remaining processes and force kill if necessary
    remaining_pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')
    if [ -n "$remaining_pids" ]; then
        echo "Force killing remaining PIDs: $remaining_pids..."
        for pid in $remaining_pids; do
            kill -9 "$pid" && echo "Force killed PID $pid" || echo "Failed to force kill PID $pid"
        done
    else
        echo "No remaining processes."
    fi
else
    echo "No running process found."
fi

echo "Step 3: Disabling service from autostart..."
if [ -f "$service_file" ]; then
    "$service_file" disable
    echo "Service disabled."
else
    echo "No service file found."
fi

echo "Step 4: Removing service file..."
if [ -f "$service_file" ]; then
    rm -f "$service_file"
    echo "Service file removed."
else
    echo "No service file found."
fi

echo "Step 5: Cleaning up temporary files..."
[ -f "/var/run/$process_name.pid" ] && rm -f "/var/run/$process_name.pid" && echo "PID file removed."
[ -f "/tmp/$process_name.lock" ] && rm -f "/tmp/$process_name.lock" && echo "Lock file removed."

echo "Completed."
logger -t "$process_name" "Service fully removed."
