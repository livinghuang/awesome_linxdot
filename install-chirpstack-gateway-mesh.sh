#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start chirpstack-gateway-mesh service (border or relay) in the background.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Improved service handling, cron job placement, and stop functionality.

# --- Parameters ---
role="${1:-border}"   # Default: border
region="${2:-as923}"  # Default: as923

# Validate role
if [ "$role" != "border" ] && [ "$role" != "relay" ]; then
    echo "Error: Invalid role '$role'. Use 'border' or 'relay'."
    exit 1
fi

service_name="linxdot-chirpstack-gateway-mesh"
service_file="/etc/init.d/${service_name}"
run_script="/opt/awesome_linxdot/run_chirpstack_gateway_mesh.sh"

echo "Step 1: Checking if the ChirpStack Gateway Mesh ($role) service is installed..."

# --- Service File Creation ---
if [ ! -f "$service_file" ]; then
    echo "Service not found. Creating service file for role: $role, region: $region..."

    cat << EOF > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "chirpstack-gateway-mesh-$role" "Starting service with role: ${role}, region: ${region}..."

    procd_open_instance
    procd_set_param command "${run_script}" "${role}" "${region}"
    procd_set_param respawn 3600 5 0  # Restart after 3600s, max 5 retries
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack-gateway-mesh-$role" "Service started successfully!"
}

stop_service() {
    logger -t "chirpstack-gateway-mesh-$role" "Stopping service..."
    procd_kill
}

EOF

    # Make the service file executable
    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service to start on boot
    /etc/init.d/${service_name} enable

    # Start the service immediately
    /etc/init.d/${service_name} start

    echo "Service '$service_name' enabled and started."
else
    echo "Service '$service_name' already exists."
fi

# --- Add Cron Job for Relay Role ---
if [ "$role" = "relay" ]; then
    echo "*/5 * * * * /opt/awesome_linxdot/awesome-software/mesh_relay_time_sync/mesh_relay_time_sync" > /etc/crontabs/root
    /etc/init.d/cron restart
    logger -t "chirpstack-gateway-mesh-$role" "Cron job for mesh relay time sync added."
fi

echo "Step 2: Service installation and startup completed!"
