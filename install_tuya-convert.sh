#!/usr/bin/env bash

# Setup script
set -o errexit  # Exit immediately if a pipeline returns a non-zero status
set -o errtrace # Trap ERR from shell functions, command substitutions, and commands from subshell
set -o nounset  # Treat unset variables as an error
set -o pipefail # Pipe will exit with last non-zero status if applicable
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

# Error handling function with enhanced debugging output
function error_exit() {
  trap - ERR
  local DEFAULT='Unknown failure occurred.'
  local REASON="\e[97m${1:-$DEFAULT}\e[39m"
  local FLAG="\e[91m[ERROR:LXC] \e[93m$EXIT@$LINE"
  local CMD="$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//')"
  local FUNCNAME="${FUNCNAME[1]:-MAIN}"
  local BASH_SOURCE="${BASH_SOURCE[1]:-N/A}"
  
  local LINE_CONTENT=""
  if [ -f "$BASH_SOURCE" ]; then
    LINE_CONTENT=$(sed "${LINE}q;d" "$BASH_SOURCE")
  else
    LINE_CONTENT="Unable to retrieve line content."
  fi

  msg "$FLAG $REASON"
  msg "\e[91m[DEBUG] Command:\e[39m $CMD"
  msg "\e[91m[DEBUG] File:\e[39m $BASH_SOURCE"
  msg "\e[91m[DEBUG] Function:\e[39m $FUNCNAME"
  msg "\e[91m[DEBUG] Line:\e[39m $LINE"
  msg "\e[91m[DEBUG] Line Content:\e[39m $LINE_CONTENT"
  
  exit $EXIT
}

function warn() {
  local REASON="\e[97m$1\e[39m"
  local FLAG="\e[93m[WARNING]\e[39m"
  msg "$FLAG $REASON"
}

function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

# Default variables
LOCALE=${1:-en_US.UTF-8}
export PATH=$PATH:/usr/sbin  # Ensure /usr/sbin is in the PATH

# Prepare container OS
msg "Customizing container OS..."
echo "root:tuya" | chpasswd
sed -i "s/\(# \)\($LOCALE.*\)/\2/" /etc/locale.gen
export LANGUAGE=$LOCALE LANG=$LOCALE
locale-gen >/dev/null
cd /root

# Detect DHCP address with retry loop
while [ "$(hostname -I)" = "" ]; do
  COUNT=$((${COUNT-} + 1))
  warn "Failed to grab an IP address, waiting...$COUNT"
  if [ $COUNT -eq 10 ]; then
    die "Unable to verify assigned IP address. Check network configuration."
  fi
  sleep 1
done

# Update container OS
msg "Updating container OS..."
apt-get update >/dev/null
apt-get -qqy upgrade &>/dev/null

# Install prerequisites
msg "Installing prerequisites..."
echo "samba-common samba-common/dhcp boolean false" | debconf-set-selections
apt-get -qqy install \
  git curl network-manager net-tools samba &>/dev/null

# Clone tuya-convert
msg "Cloning tuya-convert..."
git clone --quiet https://github.com/ct-Open-Source/tuya-convert

# Configure tuya-convert
msg "Configuring tuya-convert..."

# Navigate to the tuya-convert directory
cd /root/tuya-convert

# Ensure 'iw' command is installed
if ! command -v iw &> /dev/null; then
  msg "'iw' command not found. Installing..."
  apt update
  apt install -y iw
fi

# Debugging: Output the path to iw command
echo "Path to 'iw' command: $(which iw)"

# Attempt to get the WLAN interface
if ! WLAN=$(iw dev | sed -n 's/[[:space:]]Interface \(.*\)/\1/p' | head -n 1); then
  echo "Failed to detect WLAN interface with 'iw' command."
  exit 1
fi
echo "Detected WLAN interface: $WLAN"

# Verify WLAN interface value and update config.txt
if [ -z "$WLAN" ]; then
  echo "No wireless interface found. Exiting."
  exit 1
fi

# Check for config.txt file before updating
if [ ! -f config.txt ]; then
  echo "config.txt file not found. Exiting."
  exit 1
fi

# Update WLAN setting in config.txt
echo "Updating WLAN in config.txt to: $WLAN"
sed -i "s/^\(WLAN=\)\(.*\)/\1$WLAN/" config.txt

# Install tuya-convert
msg "Running tuya-convert/install_prereq.sh..."
cd tuya-convert
./install_prereq.sh &>/dev/null
systemctl disable dnsmasq &>/dev/null
systemctl disable mosquitto &>/dev/null

# Customize OS
msg "Customizing OS..."
cat <<EOL >> /etc/samba/smb.conf
[tuya-convert]
  path = /root/tuya-convert
  browseable = yes
  writable = yes
  public = yes
  force user = root
EOL
cat <<EOL >> /etc/issue
  ******************************
    The tuya-convert files are
    shared using samba at
    \4{eth0}
  ******************************

  Login using the following credentials
    username: root
    password: tuya

EOL
sed -i "s/^\(root\)\(.*\)\(\/bin\/bash\)$/\1\2\/root\/login.sh/" /etc/passwd

# Cleanup
msg "Cleanup..."
rm -rf /root/install_tuya-convert.sh /var/{cache,log}/* /var/lib/apt/lists/*

msg "Setup complete."
