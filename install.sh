#!/bin/bash

# Gather Information
read -p "Enter the disk path for the boot partition (ex /dev/nvme0n1): " BOOT
read -p "Enter the disk path for the EFI partition (ex /dev/nvme0n1): " EFI
read -p "Enter the disk path for the lvm partition (ex /dev/nvme0n1): " LVM
read -p "Enter a name for the LVM volume group (ex sn850x or hynix): " VGNAME
read -p "Enter the desired encryption passphrase: " PASSPHRASE
read -p "Enter the desired size of the root partition: " ROOT
read -p "Enter the desired size of the home partition (enter 100%FREE to use remaining space): " HOME
read -p "Enter the desired user name. You will be asked to enter a password later: " USERNAME
read -p "Enter size of swapfile in megabytes (ex 8192): " SWAPSIZE
read -p "Enter the default timezone (ex US/Mountain): " TIMEZONE
read -p "Enter the desired hostname: " HOSTNAME

# Packages to Install
PACKAGES=(
    spotify-launcher
    bitwarden
    virtualbox
    gnome-disk-utility
    gparted
    filelight
    thunderbird
    obsidian
    fish
    htop
    glances
    cmatrix
    neofetch
    blender
    darktable
    freecad
    gimp
    vlc
    powertop
    code
    firefox
    git
    bluez
    bluez-utils
    blueman
    xarchiver
    unzip
    fwupd
    discord
    ufw
    git
    virtualbox-host-dkms
    virtualbox-guest-iso
    hyprland
    xorg-server
    xorg
    lightdm
    rofi
    lightdm-gtk-greeter
    qbittorrent
    tor
    pavucontrol
    pdftricks
    pulseaudio
    pulseaudio-alsa
    pulseaudio-bluetooth
    pulseaudio-equalizer
    pulseaudio-jack
    rsync
    traceroute
    wget
)

AURPACKAGES=(
    video-trimmer
    prusa-slicer
    office365-electron
    libreoffice
    deskreen
    sublime-text-4
    superslicer-bin
    steam
    rpi-imager
    google-chrome
    alacritty
    tor-browser
    thonny
    zoom
)

# Setup Encryption
echo "Encrypting disk... "

echo -n "$PASSPHRASE" | sudo cryptsetup luksFormat --batch-mode --key-file=- $LVM
cryptsetup luksOpen $LVM lvm

# Setup LVM
echo "Configuring LVM... "

pvcreate --dataalignment 1m /dev/mapper/lvm
vgcreate  $VGNAME /dev/mapper/lvm
lvcreate -L $ROOT $VGNAME -n lv_root
lvcreate -L $HOME $VGNAME -n lv_home

modprobe dm_mod
vgscan
vgchange -ay

# Format Partitions
echo "Formatting partitions... "

mkfs.ext4 /dev/$VGNAME/lv_root
mkfs.ext4 /dev/$VGNAME/lv_home

# Mount Partitions
echo "Mounting partitions... "

mount /dev/$VGNAME/lv_root /mnt
mkdir /mnt/home
mount /dev/sn850x/lv_home /mnt/home

mkdir /mnt/boot
mount /dev/sda2 /mnt/boot

# Generate fstab
echo "Generating fstab... "

mkdir /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc

# Install Base System
echo "Installing base system... "

pacstrap -i /mnt base
arch-chroot /mnt

# Install & configure required packages for installation
echo "Installing packages required for installation... "

pacman -S linux linux-headers linux-lts linux-lts-headers nano base-devel openssh networkmanager wpa_supplicant wireless_tools netctl dialog lvm2 sudo --noconfirm
systemctl enable sshd NetworkManager

# Modify kernel parameters
echo "Modifying kernel parameters... "

sed -i '/^HOOKS=/s/block /block encrypt lvm2 /' /etc/mkinitcpio.conf
mkinitcpio -p linux
mkinitcpio -p linux-lts

# Set locale
echo "Setting locale... "

sed -i '/^#.*en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf

# User & Password configuration
echo "Configuring user and passwords... "

passwd
useradd -m -g users -G wheel $USERNAME
passwd $USERNAME
sudo sed -i '/^#%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers

# Configure GRUB
echo "Installing GRUB bootloader... "

pacman -S grub efibootmgr dosfstools os-prober mtools --noconfirm
mkdir /boot/EFI
mount /dev/$EFI /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=sn850x_grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub && \
sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s/"$/ cryptdevice=\/dev\/sda3:sn850x:allow-discards"/' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

# Configure Swap
echo "Creating swap file... "

dd if=/dev/zero of=/swapfile bs=1M count=$SWAPSIZE status=progress
chmod 600 /swapfile
mkswap /swapfile
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
cat /etc/fstab
mount -a
swapon -a

# Configure Host Details
echo "Setting host details... "

timedatectl set-timezone $TIMEZONE
systemctl enable systemd-timesyncd
hostnamectl set-hostname $HOSTNAME

# Install ucode & Firmware
echo "Installing ucode and firmware... "

pacman -S intel-ucode nvidia nvidia-lts linux-firmware --noconfirm

# Install xfce4
echo "Installing xfce4 desktop environment... "

pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xorg xorg-server --noconfirm
systemctl enable lightdm

# Install packages
echo "Installing user packages from official repositories... "

for package in "${PACKAGES[@]}"; do
    echo "Installing $package..."
    sudo pacman -S --noconfirm "$package"
done

# Configure yay
echo "Setting up yay aur manager... "

mkdir /home/$USERNAME/repositories
git clone https://aur.archlinux.org/yay-bin
chmod 700 yay-bin
cd yay
makepkg -si
cd ..

# Install yay Packages
echo "Installing user packages from the AUR... "

for package in "${PACKAGES[@]}"; do
    echo "Installing $package..."
    sudo yay -S --noconfirm "$package"
done

# Configure ufw firewall
echo "Configuring UFW firewall... "

ufw enable
ufw default deny incoming
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 53
ufw allow 123

# Enable Bluetooth
echo "Enabling bluetooth... "

systemctl enable bluetooth

