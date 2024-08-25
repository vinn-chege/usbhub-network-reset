#!/bin/bash

# The network interface name (change as needed)
INTERFACE="enx00e04c3657ae"

# Function to reset USB hub
reset_usb_hub() {
    # Find the USB hub bus and device numbers dynamically
    USB_HUB=$(lsusb | grep "214b:7250") # Use the USB hub's ID
    if [ -z "$USB_HUB" ]; then
        echo "USB hub not found"
        exit 1
    fi

    # Extract bus and device numbers
    BUS=$(echo $USB_HUB | awk '{print $2}')
    DEVICE=$(echo $USB_HUB | awk '{print $4}' | sed 's/://')

    # Unbind and bind the USB hub
    echo "Resetting USB hub on bus $BUS and device $DEVICE"
    echo -n "$BUS-$DEVICE" | sudo tee /sys/bus/usb/drivers/usb/unbind
    sleep 2
    echo -n "$BUS-$DEVICE" | sudo tee /sys/bus/usb/drivers/usb/bind
}

# Main script to check and reset the interface
check_and_reset_interface() {
    # Check if the interface is up
    if ! /sbin/ip link show $INTERFACE | grep -q "UP"; then
        echo "Interface $INTERFACE is down, attempting to bring it up."
        # Bring the interface down and up
        sudo ip link set $INTERFACE down
        sudo ip link set $INTERFACE up

        # Only reset the USB hub if the interface is still down
        if ! /sbin/ip link show $INTERFACE | grep -q "UP"; then
            echo "Interface $INTERFACE is still down, resetting USB hub."
            reset_usb_hub
        fi
    else
        echo "Interface $INTERFACE is already up."
    fi
}

# Function to create the systemd service file
create_systemd_service() {
    SERVICE_FILE="/etc/systemd/system/reset-network.service"

    echo "Creating systemd service file at $SERVICE_FILE"

    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Network Interface and USB Hub Reset Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/reset-network.sh
Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOL

    echo "Reloading systemd manager configuration"
    sudo systemctl daemon-reload

    echo "Enabling the reset-network service to start on boot"
    sudo systemctl enable reset-network.service

    echo "Starting the reset-network service"
    sudo systemctl start reset-network.service
}

# Function to deploy the script and service
deploy_script_and_service() {
    SCRIPT_PATH="/usr/local/bin/reset-network.sh"

    echo "Deploying the script to $SCRIPT_PATH"
    sudo tee $SCRIPT_PATH > /dev/null <<EOL
#!/bin/bash

# The network interface name (change as needed)
INTERFACE="$INTERFACE"

# Function to reset USB hub
reset_usb_hub() {
    # Find the USB hub bus and device numbers dynamically
    USB_HUB=\$(lsusb | grep "214b:7250") # Use the USB hub's ID
    if [ -z "\$USB_HUB" ]; then
        echo "USB hub not found"
        exit 1
    fi

    # Extract bus and device numbers
    BUS=\$(echo \$USB_HUB | awk '{print \$2}')
    DEVICE=\$(echo \$USB_HUB | awk '{print \$4}' | sed 's/://')

    # Unbind and bind the USB hub
    echo "Resetting USB hub on bus \$BUS and device \$DEVICE"
    echo -n "\$BUS-\$DEVICE" | sudo tee /sys/bus/usb/drivers/usb/unbind
    sleep 2
    echo -n "\$BUS-\$DEVICE" | sudo tee /sys/bus/usb/drivers/usb/bind
}

# Check if the interface is up
if ! /sbin/ip link show \$INTERFACE | grep -q "UP"; then
    echo "Interface \$INTERFACE is down, attempting to bring it up."
    # Bring the interface down and up
    sudo ip link set \$INTERFACE down
    sudo ip link set \$INTERFACE up

    # Only reset the USB hub if the interface is still down
    if ! /sbin/ip link show \$INTERFACE | grep -q "UP"; then
        echo "Interface \$INTERFACE is still down, resetting USB hub."
        reset_usb_hub
    fi
else
    echo "Interface \$INTERFACE is already up."
fi
EOL

    echo "Making the script executable"
    sudo chmod +x $SCRIPT_PATH

    # Create the systemd service
    create_systemd_service
}

# Execute deployment
deploy_script_and_service
