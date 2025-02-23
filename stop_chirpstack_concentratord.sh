#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop the ChirpStack Concentratord process.
# Author: Living Huang
# Date: 2025-02-23

process_name="chirpstack-concentratord-sx1302"

echo "Step 1: Stopping ChirpStack Concentratord process..."
logger -t "chirpstack-concentratord" "Attempting to stop process: $process_name"

# Check if the process is running
pid=$(pgrep -f "$process_name")

if [ -n "$pid" ]; then
    echo "Found process with PID(s): $pid. Stopping..."
    logger -t "chirpstack-concentratord" "Found process with PID(s): $pid. Sending termination signal."
    
    # Kill the process
    kill "$pid"

    # Wait until the process stops
    sleep 2
    if pgrep -f "$process_name" > /dev/null; then
        echo "Process did not stop. Forcing termination..."
        logger -t "chirpstack-concentratord" "Process did not stop. Forcing termination."
        kill -9 "$pid"
    else
        echo "Process stopped successfully."
        logger -t "chirpstack-concentratord" "Process stopped successfully."
    fi
else
    echo "No running process found for $process_name."
    logger -t "chirpstack-concentratord" "No running process found."
fi

echo "Step 2: ChirpStack Concentratord stop process completed."
