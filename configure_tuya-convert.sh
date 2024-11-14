#!/usr/bin/env bash

# Setup script
set -o errexit  # Exit immediately if a pipeline returns a non-zero status
set -o errtrace # Trap ERR from shell functions, command substitutions, and commands from subshell
set -o nounset  # Treat unset variables as an error
set -o pipefail # Pipe will exit with last non-zero status if applicable

# Ensure PATH includes directories where system binaries are located
export PATH=$PATH:/sbin:/usr/sbin

# Navigate to the tuya-convert directory
cd /root/tuya-convert

# Check if 'iw' is installed and available in the system PATH
if ! command -v iw &> /dev/null; then
    echo "'iw' command not found. Installing..."
    sudo apt update
    sudo apt install -y iw
fi

# Debugging: Output the path to iw command
echo "Path to 'iw' command: $(which iw)"

# Debugging: Check if iw is accessible
if ! sudo /usr/sbin/iw dev &> /dev/null; then
    echo "Error: 'iw' command failed. Exiting."
    exit 1
fi

# Attempt to get the WLAN interface
WLAN=$(sudo /usr/sbin/iw dev | sed -n 's/[[:space:]]*Interface \(.*\)/\1/p' | head -n 1)

# Debugging: Check the value of WLAN
echo "Detected WLAN interface: $WLAN"

# Verify that WLAN was set correctly
if [ -z "$WLAN" ]; then
    echo "No wireless interface found. Exiting."
    exit 1
fi

# Update WLAN setting in config.txt
echo "Updating WLAN in config.txt to: $WLAN"

# Ensure we have permissions to modify config.txt
if [ ! -f config.txt ]; then
    echo "Error: config.txt not found. Exiting."
    exit 1
fi

sudo sed -i "s/^\(WLAN=\)\(.*\)/\1$WLAN/" config.txt

echo "WLAN configuration updated successfully."
