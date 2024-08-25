# General maintenance script for arch-based linux distributions.
# Last updated by Tim True on August 24, 2024

#!/bin/bash

# Update packages with yay
yay -Syu --noconfirm --cleanbuild A

# Update firmware with fwupdmgr
pacman -S fwupd
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr upgrade

# Clear cache with pacman
pacman -Sc

# Add other commands below
