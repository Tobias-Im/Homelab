#!/bin/bash

# ==============================================================================
# REALTEK RTL8125 2.5GbE DRIVER INSTALLER (DKMS)
# ==============================================================================
# Based on the "awesometic" community repository.
# Fixes stability issues with the default 'r8169' driver in Proxmox.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SUDO PRIVILEGE CHECK
# ------------------------------------------------------------------------------
# sudo -v: Validates credentials immediately so the script doesn't pause later.
sudo -v
if [ $? -ne 0 ]; then
    echo "❌ Error: You need sudo privileges to run this script."
    exit 1
fi


# ------------------------------------------------------------------------------
# 2. INSTALL PREREQUISITES
# ------------------------------------------------------------------------------
# pve-headers is crucial for compiling the module against the specific Proxmox kernel
echo "Step 1: Installing build dependencies (pve-headers, dkms, git)..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y pve-headers dkms build-essential git

# ------------------------------------------------------------------------------
# 3. CLEANUP PREVIOUS ATTEMPTS
# ------------------------------------------------------------------------------
# Ensures we don't get "destination path already exists" errors
if [ -d "/usr/src/realtek-r8125-dkms" ]; then
    echo "Step 2: Cleaning up old source files..."
    sudo rm -rf /usr/src/realtek-r8125-dkms
fi

# ------------------------------------------------------------------------------
# 4. CLONE REPOSITORY
# ------------------------------------------------------------------------------
echo "Step 3: Cloning driver source code..."
cd /usr/src
sudo git clone https://github.com/awesometic/realtek-r8125-dkms.git
cd realtek-r8125-dkms || exit 1

# ------------------------------------------------------------------------------
# 5. RUN DKMS INSTALLER
# ------------------------------------------------------------------------------
# Note: We use ./dkms-install.sh (in root), NOT ./scripts/install.sh
echo "Step 4: Compiling and installing kernel module..."
if [ -f "./dkms-install.sh" ]; then
    sudo ./dkms-install.sh
else
    echo "❌ Error: Installer script not found. Repo structure may have changed."
    exit 1
fi

# ------------------------------------------------------------------------------
# 6. BLACKLIST OLD DRIVER
# ------------------------------------------------------------------------------
echo "Step 5: Blacklisting the unstable 'r8169' driver..."
# This prevents the kernel from loading the generic Linux driver on next boot.
echo "blacklist r8169" | sudo tee /etc/modprobe.d/blacklist-r8169.conf > /dev/null

# ------------------------------------------------------------------------------
# 7. UPDATE INITRAMFS
# ------------------------------------------------------------------------------
echo "Step 6: Updating Initial RAM Filesystem (this takes a moment)..."

# EXPLANATION:
# The Linux kernel loads network drivers VERY early from the 'initramfs' image
# (Initial RAM Filesystem) before it even mounts your hard drive.
# If we don't update this image (-u), the kernel won't know about the
# blacklist file we just created, and it will still load the old driver.
sudo update-initramfs -u

# ------------------------------------------------------------------------------
# 8. FINISH
# ------------------------------------------------------------------------------
echo "========================================================================"
echo "✅ INSTALLATION COMPLETE"
echo "========================================================================"
echo "⚠️  You must REBOOT now to apply the changes."
echo "After reboot, verify with: lspci -s 02:00.0 -k"
echo ""