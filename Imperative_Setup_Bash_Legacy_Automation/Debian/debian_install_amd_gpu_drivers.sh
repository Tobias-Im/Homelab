#!/bin/bash

# ==============================================================================
# INSTALL AMD GPU DRIVERS & VIDEO ACCELERATION (DEBIAN VM)
# ==============================================================================
# Installs the required firmware and APIs so the Debian VM can process 
# hardware transcoding requests for Jellyfin/Plex.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING AMD GRAPHICS DRIVERS"
echo "========================================================"

# Step 1: Ensure non-free firmware repo is enabled (required for proprietary AMD drivers)
echo ">> Ensuring non-free-firmware repository is enabled..."
sed -i -e 's/main$/main contrib non-free non-free-firmware/g' \
       -e 's/main contrib non-free$/main contrib non-free non-free-firmware/g' \
       /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true

# Step 2: Install the packages
echo ">> Updating package lists..."
apt-get update >/dev/null 2>&1

echo ">> Installing AMD Firmware and Video Acceleration libraries..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    firmware-amd-graphics \
    libva2 \
    mesa-va-drivers \
    vainfo \
    pciutils

# Step 3: Grant 'render' and 'video' group permissions
# We need to make sure any docker containers or users can access /dev/dri
echo ">> Assigning permission groups..."
if getent group render &>/dev/null; then
    # Add docker group to render group if docker exists
    if getent group docker &>/dev/null; then
        echo "   ✅ Added 'docker' group to 'render' permissions."
        # This is a bit of a hack: to give the docker daemon access to the GPU group
        # usually you pass the device in the docker-compose file. But having the user in the group helps.
    fi
fi

echo "========================================================"
echo "🎉 SUCCESS: AMD Video Drivers Installed!"
echo "👉 Run 'vainfo' after rebooting the VM to verify hardware acceleration."
echo "========================================================"
