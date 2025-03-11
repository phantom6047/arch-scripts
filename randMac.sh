#!/bin/bash

# Prompt the user for the network interface
read -p "Enter the network interface you want to randomize (e.g., eth0, wlan0, etc.): " INTERFACE

while true; do
    # Print a blank line
    echo

    # Disable the network interface
    echo "Disabling $INTERFACE..."
    sudo ip link set $INTERFACE down

    # Randomize the MAC address
    echo "Randomizing MAC address for $INTERFACE..."
    sudo macchanger -r $INTERFACE

    # Re-enable the network interface
    echo "Re-enabling $INTERFACE..."
    sudo ip link set $INTERFACE up

    # Display time network was reenabled. 
    echo "Current time: $(date +"%I:%M:%S %p")"

    # Wait for 30 minutes before repeating the process
    echo "Waiting for 30 minutes..."
    sleep 1800

done

