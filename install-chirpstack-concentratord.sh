#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start chirpstack-concentratord service in the background.
# Author: Living Huang
# Date: 2025-02-23

region="as923"
service_file="/etc/init.d/linxdot-chirpstack-concentratord"
run_script="/opt/awesome_linxdot/run_chirpstack_concentratord.sh"

echo "Step 1: Checking if the ChirpStack Concentratord service is installed..."

# Check if the service file exists
if [ ! -f "$service_file" ]; then
    echo "-------- Service not found. Creating service file..."

    cat << EOF > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "chirpstack-concentratord" "Starting service with region: ${region}..."

    procd_open_instance
    procd_set_param command "${run_script}" "${region}"
    procd_set_param respawn 3600 5 0  # Respawn: max 5 retries with 1-hour interval to prevent crash loops
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack-concentratord" "Service started successfully!"
}

stop_service() {
    logger -t "chirpstack-concentratord" "Stopping service..."
}
EOF

    # Make the service script executable
    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service to start on boot
    "$service_file" enable

    # Start the service immediately
    "$service_file" start
else
    echo "Service already exists. Restarting..."
    "$service_file" restart
fi

echo "Step 2: Service installation and startup completed!"
