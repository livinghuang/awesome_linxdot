import re
import datetime
import os
import subprocess

# Log file path (only process last 500 lines)
log_file = "/usr/bin/init_log/syslog.log"

# Extract relevant log lines and save to logread.txt
try:
    subprocess.run(f"tail -n 500 {log_file} | grep 'tv_sec' > logread.txt", shell=True, check=True)
except subprocess.CalledProcessError:
    print(f"Error: Could not process log file {log_file}.")
    exit(1)

# Read extracted logs
try:
    with open("logread.txt", "r", encoding="utf-8") as file:
        log_messages = file.read()
except FileNotFoundError:
    print("Error: logread.txt not found.")
    exit(1)

# Regex pattern to extract tv_sec timestamps
pattern = r"tv_sec:\s*(\d+)"
matches = [int(match) for match in re.findall(pattern, log_messages)]

# Get the latest timestamp
if matches:
    latest_timestamp = max(matches)
    converted_time = datetime.datetime.fromtimestamp(latest_timestamp, datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

    # Get current system time
    current_timestamp = int(datetime.datetime.now().timestamp())

    print(f"Latest tv_sec from logs: {latest_timestamp} => {converted_time}")
    print(f"Current system time: {current_timestamp} => {datetime.datetime.fromtimestamp(current_timestamp, datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}")

    # Check if the system time is already ahead
    if current_timestamp >= latest_timestamp:
        print("System time is already up-to-date. No update needed.")
    else:
        # Update system time
        os.system(f"date -s '{converted_time}'")
        print(f"System time has been updated to: {converted_time}")

        # Sync hardware clock (if available)
        if os.system("command -v hwclock") == 0:
            os.system("hwclock -w")
            print("Time has been synchronized to hardware clock.")
        else:
            print("Warning: 'hwclock' not found. Skipping hardware clock synchronization.")
else:
    print("No valid timestamps found in the logs.")
