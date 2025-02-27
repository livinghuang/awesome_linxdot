#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start chirpstack-concentratord service, then copy LuCI files.
# Author: Living Huang
# Date: 2025-02-23

region="as923"
service_file="/etc/init.d/linxdot-chirpstack-concentratord"
run_script="/opt/awesome_linxdot/run_chirpstack_concentratord.sh"
luci_source_dir="/opt/awesome_linxdot/luci"
luci_controller_dest="/usr/lib/lua/luci/controller"
luci_view_dest="/usr/lib/lua/luci/view"

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
    procd_set_param respawn 3600 5 0  # Respawn: max 5 retries with 1-hour interval
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack-concentratord" "Service started successfully!"
}

stop_service() {
    logger -t "chirpstack-concentratord" "Stopping service..."
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    "$service_file" enable
fi

# Start the service
"$service_file" start

echo "Step 2: Copying LuCI files..."

# Ensure target directories exist
mkdir -p "$luci_controller_dest"
mkdir -p "$luci_view_dest"

# Copy LuCI controller files (.lua)
if [ -d "$luci_source_dir/controller" ]; then
    cp -r "$luci_source_dir/controller/"* "$luci_controller_dest/"
    echo "Copied LuCI controller files to $luci_controller_dest"
fi

# Copy LuCI view files (.htm)
if [ -d "$luci_source_dir/view" ]; then
    cp -r "$luci_source_dir/view/"* "$luci_view_dest/"
    echo "Copied LuCI view files to $luci_view_dest"
fi

# Set file permissions
chmod -R 644 "$luci_controller_dest"/*
chmod -R 644 "$luci_view_dest"/*

echo "Step 3: Restarting LuCI services..."

# Clear LuCI cache and restart services
rm -rf /tmp/luci-*
/etc/init.d/rpcd restart
/etc/init.d/nginx restart  # If using nginx, otherwise use /etc/init.d/uhttpd restart

echo "Step 4: LuCI page is ready! You can find it under Status → ChirpStack"
