#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the lora_pkt_fwd service and turn off LEDs.
# Author: Living Huang
# Date: 2025-02-23

service_file="/etc/init.d/linxdot-lora-pkt-fwd"
process_name="lora_pkt_fwd"

# LED paths
led1="/sys/devices/platform/leds/leds/work-led1/brightness"
led2="/sys/devices/platform/leds/leds/work-led2/brightness"

echo "Step 1: Attempting to stop lora_pkt_fwd via init.d service..."
logger -t "$process_name" "Attempting to stop service."

# Step 1: Stop the service if it exists
if [ -f "$service_file" ]; then
    "$service_file" stop
    echo "Service stop command issued."
    logger -t "$process_name" "Service stop command issued."
    sleep 2
else
    echo "Warning: Service file not found. Proceeding to kill process directly."
    logger -t "$process_name" "Service file not found. Proceeding to direct process termination."
fi

echo "Step 2: Checking for running processes..."
pid=$(pgrep -f "$process_name")

if [ -n "$pid" ]; then
    echo "Found running process with PID(s): $pid. Attempting to terminate..."
    logger -t "$process_name" "Found PID(s): $pid. Sending termination signal."

    # Attempt graceful kill
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

echo "Step 3: Turning off LEDs..."
if [ -w "$led1" ]; then
    echo 0 > "$led1"
    logger -t "$process_name" "LED1 turned off."
fi

if [ -w "$led2" ]; then
    echo 0 > "$led2"
    logger -t "$process_name" "LED2 turned off."
fi

echo "Step 4: Disabling service from autostart..."
if [ -f "$service_file" ]; then
    "$service_file" disable
    echo "Service disabled from autostart."
    logger -t "$process_name" "Service disabled."
else
    echo "No service file found to disable."
    logger -t "$process_name" "No service file found to disable."
fi

echo "Step 5: Removing service file from /etc/init.d/..."
if [ -f "$service_file" ]; then
    rm -f "$service_file"
    echo "Service file removed."
    logger -t "$process_name" "Service file removed."
else
    echo "No service file found to remove."
    logger -t "$process_name" "No service file found to remove."
fi

echo "Step 6: lora_pkt_fwd stop and removal process completed."
logger -t "$process_name" "Stop and removal completed."
