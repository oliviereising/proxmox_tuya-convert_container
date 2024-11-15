# New Proxmox tuya-convert Container

This script will create a new Proxmox LXC container with the latest Debian and setup tuya-convert. To create a new LXC container, run the following in a SSH session or the console from Proxmox interface

```
sudo bash -c "$(wget -qLO - https://github.com/whiskerz007/proxmox_tuya-convert_container/raw/master/create_container.sh)"
```

During the setup process, you may be prompted to select your storage location or wireless interface (if you have more than one usable option). The wireless interface will be assigned to container. _(Note: When the container is running, no other container or VM will have access to the interface.)_ After the successful completion of the script, start the container identified by the script, then use the login credentials shown to start the tuya-convert script. If you need to stop tuya-convert, press `CTRL + C`, tuya-convert will be halted, and you will be brought back to the login prompt. If you login again it will start tuya-convert again.

## Prerequisite

In order for this script to work appropriately, you must first have the drivers installed and setup correctly for your WiFi adapter in Proxmox. The beginning the of the script will test for valid WLAN interfaces. An error will be produced if one can not be found.

## Custom Firmware

To add custom firmware (not supplied by tuya-convert), connect to the samba share created by the container (details are provided at the login prompt) and add the binary to the `tuya-convert/files/` folder. Your binary will listed under the custom firmware menu.
