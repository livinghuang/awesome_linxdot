# ChirpStack Installation Scripts

This repository contains installation scripts for setting up various ChirpStack components and related services. Each script automates the installation and configuration process for a specific component.

## Installation Scripts

### 1. `install-chirpstack.sh`
Installs the ChirpStack network server and application server, which are essential for managing LoRaWAN devices.

#### Script Details:
The `install-chirpstack.sh` script launches the ChirpStack Concentratord service in the background. It includes process management, region configuration, and logging features.

**Features:**
- Supports region configuration (default: `as923`)
- Verifies required directories and executables
- Ensures necessary `.toml` configuration files exist
- Prevents duplicate processes from running
- Automatically restarts on unexpected termination

**Configuration Files:**
Located in `chirpstack-software/chirpstack-docker/configuration/chirpstack`:
- `chirpstack.toml`
- `channels_<region>.toml`
- `region_<region>.toml`

**Usage:**
```sh
./install-chirpstack.sh
```

**Stopping the Service:**
```sh
./stop_chirpstack.sh
```

**Modifying Configuration Files:**
Stop the service before modifying `.toml` files, then restart it:
```sh
./stop_chirpstack.sh
# Modify configuration files in chirpstack-software/chirpstack-docker/configuration/chirpstack
./install-chirpstack.sh
```

### 2. `install-chirpstack-concentratord.sh`
Installs the ChirpStack Concentratord, which interfaces with LoRa concentrator hardware.

**Usage:**
```sh
./install-chirpstack-concentratord.sh
```

**Stopping the Service:**
```sh
./stop_and_remove_chirpstack_concentratord.sh
```

**Modifying Configuration Files:**
Stop the service, update `.toml` files in `chirpstack-software/chirpstack-concentratord-binary/config`, then reinstall:
```sh
./stop_and_remove_chirpstack_concentratord.sh
./install-chirpstack-concentratord.sh
```

### 3. `install-chirpstack-gateway-mesh.sh`
Sets up ChirpStack Gateway Mesh for multi-gateway networking.

**Usage:**
```sh
./install-chirpstack-gateway-mesh.sh [role] [region]
```

**Stopping the Service:**
```sh
./stop_and_remove_chirpstack_gateway_mesh.sh
```

**Modifying Configuration Files:**
Stop the service, edit `.toml` files in `chirpstack-software/chirpstack-gateway-mesh-binary/config`, then reinstall:
```sh
./stop_and_remove_chirpstack_gateway_mesh.sh
./install-chirpstack-gateway-mesh.sh
```

### 4. `install-chirpstack-mqtt-forwarder.sh`
Installs the MQTT forwarder to relay LoRaWAN packets.

**Usage:**
```sh
./install-chirpstack-mqtt-forwarder.sh [role]
```

**Stopping the Service:**
```sh
./stop_and_remove_chirpstack_mqtt_forwarder.sh
```

### 5. `install-chirpstack-udp-forwarder.sh`
Installs the UDP forwarder for gateway communication.

**Usage:**
```sh
./install-chirpstack-udp-forwarder.sh
```

**Stopping the Service:**
```sh
./stop_and_remove_chirpstack_udp_forwarder.sh
```

### 6. `install-lora-pkd-fwd.sh`
Installs a LoRa packet forwarder for gateway communication.

**Usage:**
```sh
./install-lora-pkd-fwd.sh
```

**Stopping the Service:**
```sh
./stop_and_remove_lora_pkt_fwd.sh
```

## Prerequisites
Ensure your system meets these requirements before running the scripts:
- A compatible Linux distribution (such as Ubuntu or OpenWrt)
- `bash` shell installed
- Root or sudo privileges
- Internet connectivity to download dependencies

## License
This project is open-source and distributed under the MIT License.

## Contribution
If you find issues or want to contribute improvements, submit a pull request.

## Contact
For support or questions, use the repository's issue tracker or relevant community forums.

