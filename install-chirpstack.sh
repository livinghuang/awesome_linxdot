#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install ChirpStack service on LD1001/LD1002 hotspot.
# Author: Living Huang
# Date: 2025-02-23

# Variables
SYSTEM_DIR="/opt/awesome_linxdot/chirpstack-software"
SERVICE_FILE="/etc/init.d/linxdot-chirpstack-service"
DOCKER_CONFIG="/etc/docker/daemon.json"

# Detect Docker Compose command
if command -v docker-compose > /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' is available!"
    exit 1
fi

echo "Using Docker Compose command: $DOCKER_COMPOSE_CMD"

echo "Step 1: Checking dependencies..."
if ! command -v docker > /dev/null 2>&1; then
    echo "Error: Docker is not installed! Please install Docker first."
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running! Please start the Docker service."
    exit 1
fi

# Ensure jq is installed
if ! command -v jq > /dev/null 2>&1; then
    echo "Error: jq is not installed! Installing..."
    opkg update && opkg install jq
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

# Wait for Docker service to fully start
echo "Waiting for Docker service to start..."
RETRY=0
while ! docker info > /dev/null 2>&1; do
    sleep 2
    RETRY=$((RETRY+1))
    if [ $RETRY -gt 10 ]; then
        echo "Error: Docker startup timeout! Please check manually."
        exit 1
    fi
done
echo "Docker service is up and running!"

# Step 3: Checking if ChirpStack service is installed
echo "Step 3: Checking if ChirpStack service is installed..."

if [ ! -f "$SERVICE_FILE" ] || ! grep -q "chirpstack" "$SERVICE_FILE"; then
    echo "-------- Service not found or incorrect. Creating service file."

    cat << EOF > "$SERVICE_FILE"
#!/bin/sh /etc/rc.common
START=99

start() {
    logger -t "chirpstack" "Starting ChirpStack service..."
    cd /opt/awesome_linxdot/chirpstack-software/chirpstack-docker || {
        logger -t "chirpstack" "Failed to change directory."
        exit 1
    }

    if $DOCKER_COMPOSE_CMD up -d --remove-orphans; then
        logger -t "chirpstack" "ChirpStack service started successfully."
    else
        logger -t "chirpstack" "Failed to start ChirpStack service."
    fi
}

stop() {
    logger -t "chirpstack" "Stopping ChirpStack service..."
    cd /opt/awesome_linxdot/chirpstack-software/chirpstack-docker && $DOCKER_COMPOSE_CMD down
}
EOF

    chmod +x "$SERVICE_FILE"
    echo "Service file created and made executable."

    # Enable the service to start at boot
    "$SERVICE_FILE" enable

    # Start the service immediately
    "$SERVICE_FILE" start
else
    echo "ChirpStack service already exists. Restarting it..."
    "$SERVICE_FILE" restart
fi

echo "Step 4: Installation and service startup completed!"
