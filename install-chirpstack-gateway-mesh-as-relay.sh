#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start the chirpstack-gateway-mesh service in the background.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Improved error handling, logging, and added service existence checks.

region="as923"
service_file="/etc/init.d/chirpstack-gateway-mesh"
run_script="/opt/awesome_linxdot/run_chirpstack_gateway_mesh_as_relay.sh"
log_tag="chirpstack-gateway-mesh"

echo "Step 1: Checking if the ChirpStack Gateway Mesh service is installed..."
logger -t "$log_tag" "Installation check initiated."

# Check if the service file already exists
if [ -f "$service_file" ]; then
    echo "Service already exists. Skipping creation."
    logger -t "$log_tag" "Service file already exists at $service_file. Skipping creation."
else
    echo "Service not found. Creating service file..."
    logger -t "$log_tag" "Creating new service file at $service_file."

    cat << EOF > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "$log_tag" "Starting service with region: ${region}..."

    procd_open_instance
    procd_set_param command "${run_script}" "${region}"
    procd_set_param respawn 3600 5 0  # Respawn after 1 hour, max 5 retries
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "$log_tag" "Service started successfully."
}

stop_service() {
    logger -t "$log_tag" "Stopping service..."
    procd_kill
    logger -t "$log_tag" "Service stopped."
}
EOF

    # Make the service file executable
    if chmod +x "$service_file"; then
        echo "Service file created and made executable."
        logger -t "$log_tag" "Service file created and made executable."
    else
        echo "Failed to set service file as executable."
        logger -t "$log_tag" "Error: Failed to set service file as executable."
        exit 1
    fi

    # Enable the service to start on boot
    if "$service_file" enable; then
        echo "Service enabled to start on boot."
        logger -t "$log_tag" "Service enabled to start on boot."
    else
        echo "Failed to enable service."
        logger -t "$log_tag" "Error: Failed to enable service."
        exit 1
    fi

    # Start the service immediately
    if "$service_file" start; then
        echo "Service started successfully."
        logger -t "$log_tag" "Service started successfully."
    else
        echo "Failed to start service."
        logger -t "$log_tag" "Error: Failed to start service."
        exit 1
    fi
fi

echo "Step 2: Service installation and startup completed."
logger -t "$log_tag" "Installation and startup process completed."
