#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install ChirpStack service on LD1001/LD1002 hotspot.
# Author: Living Huang
# Date: 2025-02-23

# Variables
system_dir="/opt/awesome_linxdot/chirpstack-software"
service_file="/etc/init.d/linxdot-chirpstack-service"
DOCKER_CONFIG="/etc/docker/daemon.json"

echo "Step 1: Checking dependencies..."
if ! command -v docker > /dev/null 2>&1; then
    echo "Error: Docker is not installed! Please install Docker first."
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running! Please start the Docker service."
    exit 1
fi

# Ensure docker-compose is installed
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "Error: 'docker-compose' is not installed! Installing..."
    opkg update && opkg install docker-compose
    if ! command -v docker-compose > /dev/null 2>&1; then
        echo "Error: 'docker-compose' installation failed. Please install it manually."
        exit 1
    fi
fi

# Ensure jq is installed
if ! command -v jq > /dev/null 2>&1; then
    echo "Error: jq is not installed! Installing..."
    opkg update && opkg install jq
    if ! command -v jq > /dev/null 2>&1; then
        echo "Error: jq installation failed. Please install it manually."
        exit 1
    fi
fi

# Step 2: Configure Docker log settings
echo "Step 2: Configuring Docker log settings..."
if [ -f "$DOCKER_CONFIG" ]; then
    if grep -q '"log-driver"' "$DOCKER_CONFIG"; then
        echo "Docker log settings already configured. Skipping..."
    else
        echo "Updating Docker log settings..."
        jq '. + {"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' "$DOCKER_CONFIG" > /tmp/daemon.json && mv /tmp/daemon.json "$DOCKER_CONFIG"
    fi
else
    echo "Creating Docker config file with log settings..."
    cat <<EOF > "$DOCKER_CONFIG"
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
fi

echo "Restarting Docker to apply log settings..."
/etc/init.d/dockerd restart

echo "Step 3: Checking if ChirpStack service is installed..."

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
fi

echo "Step 3: Installation and service running completed!"
