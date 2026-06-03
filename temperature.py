'''
Read SoC temperature every 2 seconds and write results to
/var/www/html/temperature_log.json.

The setup script configures this file to run at startup via autostart.
'''

import json
import time
from pathlib import Path
import os

def get_temperature():
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as temp_file:
            temp_millicelsius = int(temp_file.read().strip())
            return temp_millicelsius / 1000.0
    except FileNotFoundError:
        print(f"Error: /sys/class/thermal/thermal_zone0/temp not found.")
        return None

def log_temperature(temperature_log_path):
    temperature = get_temperature()
    if temperature is None:
        return

    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

    if not Path(temperature_log_path).exists():
        with open(temperature_log_path, 'w') as f:
            json.dump([], f)

    with open(temperature_log_path, 'r') as f:
        data = json.load(f)

    data.append({"timestamp": timestamp, "temperature": temperature})

    with open(temperature_log_path, 'w') as f:
        json.dump(data, f, indent=2)

def main():
    json_file_path = "/var/www/html/temperature_log.json"
    with open(json_file_path, 'w') as f:
        json.dump([], f)
    while True:
        log_temperature(json_file_path)
        time.sleep(2)

if __name__ == "__main__":
    main()
