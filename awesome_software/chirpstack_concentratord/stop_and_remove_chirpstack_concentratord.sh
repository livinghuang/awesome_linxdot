#!/bin/sh

INITD_PATH="/etc/init.d/linxdot_chirpstack_concentratord"

echo "Stopping and removing ChirpStack Concentratord service..."

# 停止服務
if [ -f "$INITD_PATH" ]; then
    "$INITD_PATH" stop
    "$INITD_PATH" disable
    rm "$INITD_PATH"
    echo "Service stopped and removed."
else
    echo "Service script not found at $INITD_PATH"
fi
