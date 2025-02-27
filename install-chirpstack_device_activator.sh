#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install ChirpStack service on LD1001/LD1002 hotspot.
# Author: Living Huang
# Date: 2025-02-28

# Variables
system_dir="/opt/awesome_linxdot/awesome-software/chirpstack_device_activator"
service_file="/etc/init.d/chirpstack-device-activator"

echo "Step 1: Checking if chirpstack-device-activator is installed..."

# Check if service file exists
if [ ! -f "$service_file" ]; then
    echo "-------- 2. Service not found. Creating service file."

    cat << 'EOF' > "$service_file"
#!/bin/sh /etc/rc.common
START=99

start() {
    logger -t "chirpstack-device-activator" "Starting ChirpStack-device-activator service..."
    cd /opt/awesome_linxdot/awesome-software/chirpstack_device_activator || {
        logger -t "chirpstack-device-activator" "Error: Failed to change directory."
        return 1
    }

    docker-compose up -d --remove-orphans
    if [ $? -eq 0 ]; then
        logger -t "chirpstack-device-activator" "ChirpStack service started successfully."
    else
        logger -t "chirpstack-device-activator" "Error: Failed to start ChirpStack service."
        return 1
    fi
}

stop() {
    logger -t "chirpstack-device-activator" "Stopping ChirpStack-device-activator service..."
    cd /opt/awesome_linxdot/awesome-software/chirpstack_device_activator || {
        logger -t "chirpstack-device-activator" "Error: Failed to change directory."
        return 1
    }
    docker-compose down
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service to start at boot
    /etc/init.d/chirpstack-device-activator enable

    # Start the service immediately
    /etc/init.d/chirpstack-device-activator start
else
    echo "Service already exists. Restarting it..."
    /etc/init.d/chirpstack-device-activator restart
fi

echo "Step 2: Installation and service running completed!"
