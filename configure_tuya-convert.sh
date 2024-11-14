#!/usr/bin/env bash

# Setup script
set -o errexit  # Exit immediately if a pipeline returns a non-zero status
set -o errtrace # Trap ERR from shell functions, command substitutions, and commands from subshell
set -o nounset  # Treat unset variables as an error
set -o pipefail # Pipe will exit with last non-zero status if applicable
msg "Configuring from convert file"

# Ensure PATH includes directories where system binaries are located
export PATH=$PATH:/sbin:/usr/sbin

# Navigate to the tuya-convert directory
cd /root/tuya-convert

# Remove 'sudo' commands from all .sh files in the tuya-convert directory
find ./ -name '*.sh' -exec sed -i -e "s/sudo \(-\S\+ \)*//" {} \;

# Check if 'iw' is installed and available in the system PATH
if ! command -v iw &> /dev/null; then
    echo "'iw' command not found. Installing..."
    apt update
    apt install -y iw
fi

# Debugging: Output the path to iw command
echo "Path to 'iw' command: $(which iw)"

# Debugging: Check if iw is accessible
if ! /usr/sbin/iw dev &> /dev/null; then
    echo "Error: 'iw' command failed. Exiting."
    exit 1
fi

# Attempt to get the WLAN interface
WLAN=$(/usr/sbin/iw dev | sed -n 's/[[:space:]]Interface \(.*\)/\1/p' | head -n 1)

# Debugging: Check the value of WLAN
echo "Detected WLAN interface: $WLAN"

# Verify that WLAN was set correctly
if [ -z "$WLAN" ]; then
    echo "No wireless interface found. Exiting."
    exit 1
fi

# Update WLAN setting in config.txt
echo "Updating WLAN in config.txt to: $WLAN"
sed -i "s/^\(WLAN=\)\(.*\)/\1$WLAN/" config.txt
