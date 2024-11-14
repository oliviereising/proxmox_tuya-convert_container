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

# Remove 'sudo' commands from all .sh files in the tuya-convert directory
find ./ -name '*.sh' -exec sed -i -e "s/sudo \(-\S\+ \)*//" {} \;

# Check if 'iw' is installed, and install if missing
if ! command -v iw &> /dev/null; then
    echo "'iw' command not found. Installing..."
    apt update
    apt install -y iw
fi

# Use the full path for 'iw' to ensure compatibility in script
WLAN=$(/usr/sbin/iw dev | sed -n 's/[[:space:]]Interface \(.*\)/\1/p' | head -n 1)

# Verify that WLAN was set correctly
if [ -z "$WLAN" ]; then
    echo "No wireless interface found. Exiting."
    exit 1
fi

# Update WLAN setting in config.txt
sed -i "s/^\(WLAN=\)\(.*\)/\1$WLAN/" config.txt
