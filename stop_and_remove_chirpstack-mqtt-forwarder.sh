#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the chirpstack-mqtt-forwarder service.
# Author: Living Huang
# Date: 2025-02-23

service_file="/etc/init.d/linxdot-chirpstack-mqtt-forwarder"
process_name="chirpstack-mqtt-forwarder"

echo "Step 1: Attempting to stop chirpstack-mqtt-forwarder via init.d service..."
logger -t "$process_name" "Attempting to stop service."

# Stop the service if it exists
if [ -f "$service_file" ]; then
    "$service_file" stop
    echo "Service stop command issued."
    logger -t "$process_name" "Service stop command issued."
    sleep 2
else
    echo "Warning: Service file not found. Skipping service stop."
    logger -t "$process_name" "Service file not found. Proceeding to process termination."
fi

echo "Step 2: Checking for running processes..."
pid=$(pgrep -f "$process_name")

if [ -n "$pid" ]; then
    echo "Found running process with PID(s): $pid. Attempting to terminate..."
    logger -t "$process_name" "Found PID(s): $pid. Sending termination signal."

    kill "$pid"
    sleep 2

    # Force kill if still running
    if pgrep -f "$process_name" > /dev/null; then
        echo "Process did not stop. Forcing termination with kill -9..."
        logger -t "$process_name" "Process did not stop. Forcing kill -9."
        kill -9 "$pid"
    else
        echo "Process terminated successfully."
        logger -t "$process_name" "Process terminated successfully."
    fi
else
    echo "No running process found for $process_name."
    logger -t "$process_name" "No running process found."
fi

echo "Step 3: Disabling service from autostart..."
if [ -f "$service_file" ]; then
    "$service_file" disable
    echo "Service disabled."
    logger -t "$process_name" "Service disabled from startup."
else
    echo "No service file found to disable."
    logger -t "$process_name" "No service file found to disable."
fi

echo "Step 4: Removing service file from /etc/init.d/..."
if [ -f "$service_file" ]; then
    rm -f "$service_file"
    echo "Service file removed."
    logger -t "$process_name" "Service file removed from /etc/init.d/."
else
    echo "No service file found to remove."
    logger -t "$process_name" "No service file found to remove."
fi

echo "Step 5: chirpstack-mqtt-forwarder stop and removal process completed."
logger -t "$process_name" "Stop and removal completed."
