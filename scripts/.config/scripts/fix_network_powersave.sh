#!/bin/bash

# This script disables power management for the 88x2bu driver and NetworkManager
# to prevent Wi-Fi disconnections during idle/DPMS off.

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "--- Disabling 88x2bu driver power management ---"
cat <<EOF > /etc/modprobe.d/88x2bu.conf
options 88x2bu rtw_power_mgnt=0 rtw_enusbss=0
EOF

echo "--- Disabling NetworkManager Wi-Fi powersave ---"
mkdir -p /etc/NetworkManager/conf.d/
cat <<EOF > /etc/NetworkManager/conf.d/disable-wifi-powersave.conf
[connection]
wifi.powersave = 2
EOF

echo "--- Changes applied ---"
echo "Please reboot your system or run the following to apply without rebooting:"
echo "sudo systemctl restart NetworkManager"
echo "sudo modprobe -r 88x2bu && sudo modprobe 88x2bu"
