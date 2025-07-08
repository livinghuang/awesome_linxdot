#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start chirpstack-gateway-mesh service (border or relay) in the background.
# Author: Living Huang
# Date: 2025-07-08
# Updated: Improved service handling, added mesh_time_sync support for relay role.

# --- Parameters ---
role="${1:_border}"   # Default: border
region="${2:_as923}"  # Default: as923

# Validate role
if [ "$role" != "border" ] && [ "$role" != "relay" ]; then
    echo "Error: Invalid role '$role'. Use 'border' or 'relay'."
    exit 1
fi

service_name="linxdot_chirpstack_gateway_mesh"
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
    logger -t "chirpstack_gateway_mesh_$role" "Starting service with role: ${role}, region: ${region}..."

    procd_open_instance
    procd_set_param command "${run_script}" "${role}" "${region}"
    procd_set_param respawn 3600 5 0  # Restart after 3600s, max 5 retries
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack_gateway_mesh_$role" "Service started successfully!"
}

stop_service() {
    logger -t "chirpstack_gateway_mesh_$role" "Stopping service..."
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

echo "Step 3: Service installation and startup completed!"
