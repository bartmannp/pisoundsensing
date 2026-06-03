#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/sed_demo.log"

# Log the start time
echo "Script started at $(date)" >> "$LOG_FILE"

cd "$SCRIPT_DIR"

# Run sed_demo and append stdout/stderr to the same log file.
python3 -m sed_demo MODEL_PATH='Cnn9_GMP_64x64_300000_iterations_mAP=0.37.pth' >> "$LOG_FILE" 2>&1


# Then, you need to do the following
# Make the script executable:
#
# chmod +x ~/run_sed_demo.sh
# 
# Create a .desktop file that executes this script at system startup:
# 
# nano ~/.config/autostart/run_sed_demo.desktop
#
# Add the following lines to the file:
# 
#[Desktop Entry]
#Type=Application
#Name=Run sed_demo
#Exec=/path/to/pisoundsensing/run_sed_demo.sh



