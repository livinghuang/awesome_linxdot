# Gateway ID Monitor

This script reads the system log file to find the latest Gateway ID, saves it to a text file (`gatewayid.txt`), and exits. The HTML page (`gatewayid.htm`) fetches this ID dynamically for display.

## Features

- Reads the system log (`syslog.log`) to extract the latest Gateway ID.
- Saves the Gateway ID to `/www/gatewayid.txt` for web display.
- Can be manually executed or scheduled using `cron`.
- Works with OpenWrt’s built-in web server (`uHTTPd`).

---

## Installation

### 1. Clone or Create the Project Directory

```sh
mkdir -p ~/gateway_id_monitor
cd ~/gateway_id_monitor
```

### 2. Create and Activate a Virtual Environment

```sh
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Required Python Packages

```sh
pip install requests
```

### 4. Create the Python Script

```sh
vi monitor_gateway_id.py
```

Paste the following code and save (`:wq` in `vi`):

```python
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
```

---

## Usage

### 1. Run the Script Manually

```sh
python monitor_gateway_id.py
```

If a Gateway ID is found, it will be saved in `/www/gatewayid.txt`.

### 2. Check the Saved Gateway ID

```sh
cat /www/gatewayid.txt
```

If the log file contains a Gateway ID, it should be displayed.

---

## Web Interface

### 1. Create the HTML File

Move to the web directory:

```sh
cd /www
vi gatewayid.htm
```

Paste the following HTML:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gateway ID Monitor</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 20px; }
        #gateway-id { font-size: 24px; font-weight: bold; color: blue; }
    </style>
    <script>
        async function fetchGatewayID() {
            try {
                let response = await fetch('/gatewayid.txt');
                let gatewayID = await response.text();
                document.getElementById('gateway-id').innerText = gatewayID.trim();
            } catch (error) {
                console.error('Error fetching Gateway ID:', error);
            }
        }
        setInterval(fetchGatewayID, 3000); // Refresh every 3 seconds
        window.onload = fetchGatewayID;
    </script>
</head>
<body>
    <h1>Current Gateway ID</h1>
    <p id="gateway-id">Waiting for data...</p>
</body>
</html>
```

Save the file (`:wq` in `vi`).

### 2. Restart the Web Server

```sh
/etc/init.d/uhttpd restart
```

### 3. Open the Web Page

On a browser, go to:

```
http://<your-device-ip>/gatewayid.htm
```

Replace `<your-device-ip>` with the actual IP of your OpenWrt device.

---

## Automating Execution

To automatically run the script at regular intervals, set up a cron job.

### 1. Edit Crontab

```sh
crontab -e
```

Add the following line to run the script every minute:

```
* * * * * /usr/bin/python3 /root/gateway_id_monitor/monitor_gateway_id.py
```

Save and exit (`:wq` in `vi`).

### 2. Restart Cron Service

```sh
/etc/init.d/cron restart
```

Now, the script will execute automatically and update `gatewayid.txt`.

---

## Testing

### 1. Simulate a Log Entry

```sh
logger -t chirpstack-concentratord "Gateway ID retrieved, gateway_id: \"0016c001f141f857\""
```

### 2. Manually Run the Script

```sh
python monitor_gateway_id.py
```

### 3. Verify the Output

```sh
cat /www/gatewayid.txt
```

Expected output:

```
0016c001f141f857
```

---

## Notes

- The script **only runs once**, fetches the latest `gateway_id`, **saves it**, and **exits**.
- The HTML page **fetches the Gateway ID every 3 seconds**.
- Use `cron` if you want the script to run automatically.

---

## Troubleshooting

### No Gateway ID Found
1. Check if the log contains `gateway_id`:
   ```sh
   grep "gateway_id" /usr/bin/init_log/syslog.log
   ```
2. If no result, add a test log entry:
   ```sh
   logger -t chirpstack-concentratord "Gateway ID retrieved, gateway_id: \"123456abcdef\""
   ```

### Web Page Not Loading Gateway ID
1. Ensure the file exists:
   ```sh
   ls -l /www/gatewayid.txt
   ```
2. Check file permissions:
   ```sh
   chmod 666 /www/gatewayid.txt
   ```
3. Restart the web server:
   ```sh
   /etc/init.d/uhttpd restart
   ```

---

## Conclusion

This project extracts the latest `gateway_id` from system logs, saves it to a file, and provides a simple web page for real-time monitoring.

For automation, use `cron` to execute the script at fixed intervals.

