# Log Time Synchronization Script

## Overview
This script extracts timestamps from system logs, compares them with the current system time, and updates the system time if necessary. It is useful for ensuring system time accuracy, particularly when no reliable time synchronization service is available.

## Scenario
This project is an assistant program for the ChirpStack Mesh Gateway system. In case the relay gateway could not get the NTP time or GPS time, the mesh system would not be able to determine the actual situation of the relay gateway. This program will use the latest timestamp in the relay packet as the system time, ensuring that the mesh network can function correctly with accurate time synchronization.

## Features
- Extracts the latest `tv_sec` timestamp from the last 500 lines of the log file.
- Compares the extracted timestamp with the current system time.
- Updates the system time if it is behind the extracted timestamp.
- Syncs the updated time to the hardware clock (if available).

## Requirements
- Python 3
- A Linux-based system
- Root privileges (required for updating system time)
- The `hwclock` command (optional, for hardware clock synchronization)
- chirpstack-gateway-mesh-border-beacon: A modified version of chirpstack-gateway-mesh that ensures the border gateway also sends periodic heartbeat packets for system time synchronization.

## Installation
No installation is required. Ensure Python 3 is installed on your system.

## Usage
Run the script with root privileges:
```sh
sudo python3 script.py
```

## How It Works
1. The script reads the last 500 lines of the system log file (`/usr/bin/init_log/syslog.log`).
2. It extracts timestamps (`tv_sec` values) using a regex pattern.
3. The latest extracted timestamp is compared with the current system time.
4. If the system time is behind the extracted timestamp, it updates the system time using the `date -s` command.
5. If the `hwclock` command is available, it synchronizes the updated time to the hardware clock.

## Configuration
If needed, modify the log file path in the script:
```python
log_file = "/usr/bin/init_log/syslog.log"
```

## Error Handling
- If the log file is not found, the script exits with an error message.
- If no valid timestamps are found in the logs, it reports the issue.
- If the `hwclock` command is missing, it skips hardware clock synchronization and provides a warning.

## Example Output
```
Latest tv_sec from logs: 1700000000 => 2024-04-01 12:00:00
Current system time: 1699999900 => 2024-04-01 11:58:20
System time has been updated to: 2024-04-01 12:00:00
Time has been synchronized to hardware clock.
```

## Notes
- Ensure the script is run with appropriate permissions to modify the system time.
- If the log file format changes, update the regex pattern accordingly.

## License
This project is licensed under the MIT License.

