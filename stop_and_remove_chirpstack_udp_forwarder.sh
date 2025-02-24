#!/bin/sh

# Linxdot OpenSource:
# Purpose: Stop and remove the chirpstack-udp-forwarder service.
# Author: Living Huang
# Date: 2025-02-24
# Updated: Improved process termination, added clear logs, and ensured proper cleanup.

set -e  # Exit immediately if a command exits with a non-zero status

service_file="/etc/init.d/linxdot-chirpstack-udp-forwarder"
process_name="chirpstack-udp-forwarder"

echo "Step 1: Attempting to stop via init.d service..."
logger -t "$process_name" "Attempting to stop service."

if [ -f "$service_file" ]; then
    "$service_file" stop || true
    echo "Service stop issued."
    logger -t "$process_name" "Service stop issued."
    sleep 2
else
    echo "Service file not found. Proceeding..."
    logger -t "$process_name" "No service file found."
fi

echo "Step 2: Killing all running processes..."
# Find process IDs (PIDs) related to the process name
pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')

if [ -n "$pids" ]; then
    echo "Found PIDs: $pids. Attempting to kill..."
    logger -t "$process_name" "Killing PIDs: $pids"
    for pid in $pids; do
        if kill "$pid"; then
            echo "Killed PID $pid"
            logger -t "$process_name" "Killed PID $pid"
        else
            echo "Failed to kill PID $pid"
            logger -t "$process_name" "Failed to kill PID $pid"
        fi
    done

    sleep 2

    # Check for remaining processes and force kill if necessary
    remaining_pids=$(ps | grep "$process_name" | grep -v grep | grep -v "$0" | awk '{print $1}')
    if [ -n "$remaining_pids" ]; then
        echo "Force killing remaining PIDs: $remaining_pids..."
        logger -t "$process_name" "Force killing remaining PIDs: $remaining_pids"
        for pid in $remaining_pids; do
            if kill -9 "$pid"; then
                echo "Force killed PID $pid"
                logger -t "$process_name" "Force killed PID $pid"
            else
                echo "Failed to force kill PID $pid"
                logger -t "$process_name" "Failed to force kill PID $pid"
            fi
        done
    else
        echo "No remaining processes."
        logger -t "$process_name" "No remaining processes found."
    fi
else
    echo "No running process found."
    logger -t "$process_name" "No running process found."
fi

echo "Step 3: Disabling service from autostart..."
if [ -f "$service_file" ]; then
    "$service_file" disable
    echo "Service disabled."
    logger -t "$process_name" "Service disabled from autostart."
else
    echo "No service file found to disable."
fi

echo "Step 4: Removing service file..."
if [ -f "$service_file" ]; then
    rm -f "$service_file"
    echo "Service file removed."
    logger -t "$process_name" "Service file removed."
else
    echo "No service file found to remove."
fi

echo "Step 5: Cleaning up temporary files..."
[ -f "/var/run/$process_name.pid" ] && rm -f "/var/run/$process_name.pid" && echo "PID file removed." && logger -t "$process_name" "PID file removed."
[ -f "/tmp/$process_name.lock" ] && rm -f "/tmp/$process_name.lock" && echo "Lock file removed." && logger -t "$process_name" "Lock file removed."

echo "Completed."
logger -t "$process_name" "Service fully removed."
