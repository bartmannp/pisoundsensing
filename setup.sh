#!/bin/bash

# Instructions for using the script:
# Give it execute permissions with: chmod +x setup.sh
# Run with: bash ./setup.sh

set -euo pipefail

# Detect the real target user even if this script is run with sudo.
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_GROUP="$(id -gn "$TARGET_USER")"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [[ -z "$TARGET_HOME" ]]; then
	echo "Could not detect home directory for user '$TARGET_USER'."
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Use current repository folder if setup.sh lives inside it.
if [[ -f "$SCRIPT_DIR/requirements.txt" && -f "$SCRIPT_DIR/index.html" && -d "$SCRIPT_DIR/sed_demo" ]]; then
	REPO_DIR="$SCRIPT_DIR"
else
	REPO_DIR="$TARGET_HOME/pisoundsensing"
	if [[ ! -d "$REPO_DIR" ]]; then
		git clone https://github.com/bartmannp/pisoundsensing.git "$REPO_DIR"
	fi
fi

AUTOSTART_DIR="$TARGET_HOME/.config/autostart"
BACKEND_PORT="${BACKEND_PORT:-5000}"

echo "Using user: $TARGET_USER"
echo "Using repository folder: $REPO_DIR"
echo "Using backend port: $BACKEND_PORT"

# Upgrade system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
# sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev libcairo2-dev libgirepository1.0-dev python3-cryptography cython3 python3-numpy python3-pil python3-gi python3-gi-cairo gir1.2-gtk-3.0 libglib2.0-dev gcc pkg-config arandr python3-pygame portaudio19-dev python3-pil.imagetk libttspico-utils apache2 php avahi-daemon python3-torch python3-omegaconf python3-pyaudio python3-flask-cors
# 
# python3 -m pip install --upgrade pip --break-system-packages
# python3 -m pip install librosa --break-system-packages
# python3 -m pip install pyttsx3 --break-system-packages

sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev libcairo2-dev libgirepository1.0-dev python3-cryptography cython3 python3-numpy python3-pil python3-gi python3-gi-cairo gir1.2-gtk-3.0 libglib2.0-dev gcc pkg-config arandr python3-pygame portaudio19-dev python3-pil.imagetk libttspico-utils apache2 php avahi-daemon
sudo apt install python3-torch
sudo apt install python3-omegaconf
sudo apt install python3-pyaudio
sudo apt-get install python3-flask-cors

pip3 install --upgrade pip --break-system-packages
pip3 install librosa --break-system-packages
pip3 install pyttsx3 --break-system-packages

cd "$REPO_DIR"

# Update pip and setuptools
pip3 install --upgrade pip setuptools wheel --break-system-packages

# Install Flask and additional dependencies
pip3 install Flask Flask-CORS pycairo PyGObject --break-system-packages

# Install requirements from file
pip3 install -r requirements.txt --break-system-packages
pip3 install --upgrade colorama --break-system-packages


# Download .pth file if missing
MODEL_FILE="Cnn9_GMP_64x64_300000_iterations_mAP=0.37.pth"
if [[ ! -f "$MODEL_FILE" ]]; then
	wget -O "$MODEL_FILE" "https://zenodo.org/record/3576599/files/Cnn9_GMP_64x64_300000_iterations_mAP%3D0.37.pth?download=1"
fi

# Copy and configure web files
sudo cp "$REPO_DIR/index.html" /var/www/html/index.html
sudo cp "$REPO_DIR/sed_demo/assets/logo.png" /var/www/html/logo.png

# Shared runtime config consumed by the frontend and Flask app.
printf '%s\n' "{\"backend_port\": $BACKEND_PORT}" | sudo tee /var/www/html/pisoundsensing_config.json >/dev/null

sudo chown "$TARGET_USER:$TARGET_GROUP" /var/www/html/index.html /var/www/html/logo.png
sudo chown "$TARGET_USER:$TARGET_GROUP" /var/www/html/pisoundsensing_config.json
sudo chmod 644 /var/www/html/index.html /var/www/html/logo.png /var/www/html/pisoundsensing_config.json
sudo chown -R "$TARGET_USER:$TARGET_GROUP" /var/www/html/
sudo chmod -R 775 /var/www/html/

# Configure autostart for the detected user/home
mkdir -p "$AUTOSTART_DIR"

sudo chown "$TARGET_USER:$TARGET_GROUP" "$REPO_DIR/temperature.py" "$REPO_DIR/run_sed_demo.sh"
sudo chmod +x "$REPO_DIR/temperature.py" "$REPO_DIR/run_sed_demo.sh"

printf '%s\n' "[Desktop Entry]" "Type=Application" "Name=Run Temperature" "Exec=python3 $REPO_DIR/temperature.py" > "$AUTOSTART_DIR/run_temperature.desktop"

printf '%s\n' "[Desktop Entry]" "Type=Application" "Name=Run sed_demo" "Exec=$REPO_DIR/run_sed_demo.sh" > "$AUTOSTART_DIR/run_sed_demo.desktop"

sudo chown "$TARGET_USER:$TARGET_GROUP" "$AUTOSTART_DIR/run_temperature.desktop" "$AUTOSTART_DIR/run_sed_demo.desktop"
sudo chmod 644 "$AUTOSTART_DIR"/*.desktop

# Ensure generated files are editable.
touch "$REPO_DIR/state.json"
sudo chown "$TARGET_USER:$TARGET_GROUP" "$REPO_DIR/state.json"
sudo chmod 666 "$REPO_DIR/state.json"

# Reboot the system
sudo reboot

