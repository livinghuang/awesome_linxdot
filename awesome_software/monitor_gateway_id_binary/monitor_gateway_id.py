import re

log_file_path = "/usr/bin/init_log/syslog.log"
output_file = "/www/gatewayid.txt"
gateway_id_pattern = re.compile(r'gateway_id: "?([0-9a-f]+)"?')

def find_gateway_id(file_path):
    """Read the log file and extract the latest Gateway ID."""
    try:
        with open(file_path, "r") as log_file:
            for line in reversed(log_file.readlines()):  # Read from the end
                match = gateway_id_pattern.search(line)
                if match:
                    return match.group(1)
    except FileNotFoundError:
        print(f"Error: Log file {file_path} not found.")
    return None

def save_gateway_id(gateway_id):
    """Save the Gateway ID to a file for web display."""
    try:
        with open(output_file, "w") as f:
            f.write(gateway_id)
        print(f"Gateway ID saved: {gateway_id}")
    except Exception as e:
        print(f"Error writing to file: {e}")

if __name__ == "__main__":
    gateway_id = find_gateway_id(log_file_path)
    if gateway_id:
        save_gateway_id(gateway_id)
    else:
        print("No Gateway ID found.")
