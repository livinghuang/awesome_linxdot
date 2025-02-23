#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the ChirpStack Concentratord service.
# Author: Living Huang
# Date: 2025-02-23

service_file="/etc/init.d/linxdot-chirpstack-concentratord"
process_name="chirpstack-concentratord-sx1302"

echo "Step 1: Attempting to stop ChirpStack Concentratord via init.d service..."
logger -t "chirpstack-concentratord" "Attempting to stop service."

# Stop the service if it exists
if [ -f "$service_file" ]; then
    "$service_file" stop
    echo "Service stop command issued."
    logger -t "chirpstack-concentratord" "Service stop command issued."
    sleep 2  # Allow time for shutdown
else
    echo "Warning: Service file not found. Skipping service stop."
    logger -t "chirpstack-concentratord" "Service file not found. Skipping stop."
fi

echo "Step 2: Checking for lingering processes..."
pid=$(pgrep -f "$process_name")

if [ -n "$pid" ]; then
    echo "Found process with PID(s): $pid. Attempting to terminate..."
    logger -t "chirpstack-concentratord" "Terminating PID(s): $pid."

    kill "$pid"
    sleep 2

    # Force kill if still running
    if pgrep -f "$process_name" > /dev/null; then
        echo "Process did not stop. Forcing kill -9..."
        logger -t "chirpstack-concentratord" "Force killing PID(s): $pid."
        kill -9 "$pid"
    else
        echo "Process stopped successfully."
        logger -t "chirpstack-concentratord" "Process stopped successfully."
    fi
else
    echo "No running process found for $process_name."
    logger -t "chirpstack-concentratord" "No running process found."
fi

echo "Step 3: Disabling service autostart..."
if [ -f "$service_file" ]; then
    "$service_file" disable
    echo "Service disabled from startup."
    logger -t "chirpstack-concentratord" "Service disabled."
else
    echo "Service file not found. Skipping disable step."
fi

echo "Step 4: Removing service file..."
if [ -f "$service_file" ]; then
    rm -f "$service_file"
    echo "Service file removed from /etc/init.d/."
    logger -t "chirpstack-concentratord" "Service file removed."
else
    echo "No service file found to remove."
    logger -t "chirpstack-concentratord" "No service file to remove."
fi

echo "Step 5: ChirpStack Concentratord stop and removal process completed."
logger -t "chirpstack-concentratord" "Stop and removal completed."
