# General maintenance script for arch-based linux distributions.
# Last updated by Tim True on August 24, 2024

#!/bin/bash

#specify your username below
USER=tim

# Update packages with yay
sudo -u $USER yay -Syu --noconfirm 

# Update firmware with fwupdmgr
sudo pacman -S --needed fwupd
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo yes | fwupdmgr upgrade

# Clear cache with pacman
sudo pacman -Sc --noconfirm

# Add other commands below
