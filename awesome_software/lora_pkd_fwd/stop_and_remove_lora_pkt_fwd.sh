#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the lora_pkt_fwd service and turn off LEDs.

set -e  # Exit immediately if any command fails

service_file="/etc/init.d/linxdot-lora-pkt-fwd"
process_name="lora_pkt_fwd"

# LED paths
led1="/sys/devices/platform/leds/leds/work-led1/brightness"
led2="/sys/devices/platform/leds/leds/work-led2/brightness"

echo "Step 1: Attempting to stop lora_pkt_fwd via init.d service..."
logger -t "$process_name" "Attempting to stop service."

if [ -f "$service_file" ]; then
    "$service_file" stop || true
    echo "Service stop command issued."
    logger -t "$process_name" "Service stop command issued."
    sleep 2
else
    echo "Warning: Service file not found. Proceeding to kill process directly."
    logger -t "$process_name" "Service file not found. Proceeding to direct process termination."
fi

echo "Step 2: Checking for running processes..."
# Find all PIDs related to the process name, excluding grep and the script itself
pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')

if [ -n "$pids" ]; then
    echo "Found running process PID(s): $pids. Attempting to terminate..."
    logger -t "$process_name" "Terminating PID(s): $pids."

    # Attempt graceful kill
    for pid in $pids; do
        kill "$pid" && echo "Terminated PID $pid" || echo "Failed to terminate PID $pid"
    done

    sleep 2

    # Force kill if any processes are still running
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

echo "Step 3: Turning off LEDs..."
if [ -w "$led1" ]; then
    echo 0 > "$led1"
    echo "LED1 turned off."
    logger -t "$process_name" "LED1 turned off."
else
    echo "LED1 path not found or not writable."
    logger -t "$process_name" "LED1 path not found or not writable."
fi

if [ -w "$led2" ]; then
    echo 0 > "$led2"
    echo "LED2 turned off."
    logger -t "$process_name" "LED2 turned off."
else
    echo "LED2 path not found or not writable."
    logger -t "$process_name" "LED2 path not found or not writable."
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
