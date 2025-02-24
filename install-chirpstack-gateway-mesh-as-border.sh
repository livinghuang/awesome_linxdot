#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start chirpstack-gateway-mesh-as-border service in the background.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Added check for existing chirpstack-gateway-mesh services to prevent conflicts.

region="as923"
service_file="/etc/init.d/linxdot-chirpstack-gateway-mesh-as-border"
run_script="/opt/awesome_linxdot/run_chirpstack_gateway_mesh_as_border.sh"
log_tag="chirpstack-gateway-mesh-as-border"

echo "Step 1: Checking for existing ChirpStack Gateway Mesh services..."
logger -t "$log_tag" "Checking for existing services starting with 'chirpstack-gateway-mesh'."

# Check for existing services starting with "chirpstack-gateway-mesh" but not "chirpstack-gateway-mesh-as-border"
conflicting_services=$(ls /etc/init.d/ | grep "^chirpstack-gateway-mesh" | grep -v "chirpstack-gateway-mesh-as-border" || true)

if [ -n "$conflicting_services" ]; then
    echo "Conflict detected: The following service(s) may interfere with this installation:"
    echo "$conflicting_services"
    logger -t "$log_tag" "Conflict detected with existing service(s): $conflicting_services"

    echo "Please stop and remove the above service(s) before proceeding with the installation."
    echo "Example: /etc/init.d/<service_name> stop && rm /etc/init.d/<service_name>"
    logger -t "$log_tag" "Aborting installation due to conflicting services."
    exit 1
fi

echo "No conflicting services found. Proceeding with installation..."
logger -t "$log_tag" "No conflicting services detected."

# Check if the target service file already exists
if [ ! -f "$service_file" ]; then
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

else
    echo "Service already exists."
    logger -t "$log_tag" "Service already exists, skipping creation."
fi

echo "Step 2: Service installation and startup completed."
logger -t "$log_tag" "Installation and startup process completed."
