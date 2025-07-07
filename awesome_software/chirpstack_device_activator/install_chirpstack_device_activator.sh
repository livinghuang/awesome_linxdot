#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install ChirpStack service on LD1001/LD1002 hotspot.
# Author: Living Huang
# Date: 2025-02-28

# Variables
system_dir="/opt/awesome_linxdot/awesome_software/chirpstack_device_activator"
service_file="/etc/init.d/chirpstack_device_activator"

echo "Step 1: Checking if chirpstack_device_activator is installed..."

# Check if service file exists
if [ ! -f "$service_file" ]; then
    echo "-------- 2. Service not found. Creating service file."

    cat << 'EOF' > "$service_file"
#!/bin/sh /etc/rc.common
START=99

start() {
    logger -t "chirpstack_device_activator" "Starting ChirpStack_device_activator service..."
    cd /opt/awesome_linxdot/awesome_software/chirpstack_device_activator || {
        logger -t "chirpstack_device_activator" "Error: Failed to change directory."
        return 1
    }

    docker-compose up -d --remove-orphans
    if [ $? -eq 0 ]; then
        logger -t "chirpstack_device_activator" "ChirpStack service started successfully."
    else
        logger -t "chirpstack_device_activator" "Error: Failed to start ChirpStack service."
        return 1
    fi
}

stop() {
    logger -t "chirpstack_device_activator" "Stopping chirpstack_device_activator service..."
    cd /opt/awesome_linxdot/awesome_software/chirpstack_device_activator || {
        logger -t "chirpstack_device_activator" "Error: Failed to change directory."
        return 1
    }
    docker-compose down
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service to start at boot
    /etc/init.d/chirpstack_device_activator enable

    # Start the service immediately
    /etc/init.d/chirpstack_device_activator start
else
    echo "Service already exists. Restarting it..."
    /etc/init.d/chirpstack_device_activator restart
fi

echo "Step 2: Installation and service running completed!"
