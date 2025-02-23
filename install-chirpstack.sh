#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install ChirpStack service on LD1001/LD1002 hotspot.
# Author: Living Huang
# Date: 2025-02-23

# Variables
system_dir="/opt/awesome_linxdot/chirpstack-software"
service_file="/etc/init.d/linxdot-chirpstack-service"

echo "Step 1: Checking if ChirpStack service is installed..."

# Check if service file exists
if [ ! -f "$service_file" ]; then
    echo "-------- 2. Service not found. Creating service file."

    cat << 'EOF' > "$service_file"
#!/bin/sh /etc/rc.common
START=99

start() {
    logger -t "chirpstack" "Starting ChirpStack service..."
    cd /opt/awesome_linxdot/chirpstack-software/chirpstack-docker || {
        logger -t "chirpstack" "Failed to change directory."
        exit 1
    }

    if docker-compose up -d --remove-orphans; then
        logger -t "chirpstack" "ChirpStack service started successfully."
    else
        logger -t "chirpstack" "Failed to start ChirpStack service."
    fi
}

stop() {
    logger -t "chirpstack" "Stopping ChirpStack service..."
    cd /opt/awesome_linxdot/chirpstack-software/chirpstack-docker && docker-compose down
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service to start at boot
    "$service_file" enable

    # Start the service immediately
    "$service_file" start
else
    echo "Service already exists. Restarting it..."
    "$service_file" restart
fi

echo "Step 2: Installation and service running completed!"
