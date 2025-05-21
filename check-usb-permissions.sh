#!/bin/bash
# Check USB device privilege
if [ ! -r /dev/bus/usb ] || [ ! -w /dev/bus/usb ]; then
    echo "Error: Container cannot access USB devices."
    echo "Please set up udev rules on the host by runing the following comments:"
    echo " echo 'SUBSYSTEM==\"usb\", GROUP=\"lp\", MODE=\"0660\"' | sudo tee /etc/udev/rules.d/99-printer.rules"
    echo " sudo udevadm control --reload-rules"
    exit 1
fi 

# If privilege correct, continue to run cupsd
exec /usr/sbin/cupsd -f
