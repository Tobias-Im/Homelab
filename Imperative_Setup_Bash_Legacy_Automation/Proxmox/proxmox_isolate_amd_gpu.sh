#!/bin/bash

# ==============================================================================
# ISOLATE AMD GPU FOR VFIO PASSTHROUGH (PROXMOX HOST)
# ==============================================================================
# Dynamically finds the AMD GPU and its Audio controller, and assigns them 
# to the vfio-pci driver so Proxmox releases them for Virtual Machines.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 ISOLATING AMD GPU FOR PASSTHROUGH"
echo "========================================================"

# Step 1: Dynamically find the hardware IDs
echo ">> Scanning PCI devices for AMD Graphics and Audio..."

# We use lspci to find the VGA and Audio controllers, extract their [XXXX:YYYY] IDs
GPU_ID=$(lspci -nn | grep -i vga | grep -i amd | grep -o '\[[0-9a-f]\{4\}:[0-9a-f]\{4\}\]' | tr -d '[]' | head -n 1)
AUDIO_ID=$(lspci -nn | grep -i audio | grep -i amd | grep -o '\[[0-9a-f]\{4\}:[0-9a-f]\{4\}\]' | tr -d '[]' | head -n 1)

if [ -z "$GPU_ID" ]; then
    echo "   ⚠️  Could not find an AMD VGA device. (Are you testing in a VM?)"
    echo "   👉 Skipping GPU isolation."
    exit 0
fi

echo "   ✅ Found AMD GPU ID: $GPU_ID"
if [ -n "$AUDIO_ID" ]; then
    echo "   ✅ Found AMD Audio ID: $AUDIO_ID"
    VFIO_IDS="$GPU_ID,$AUDIO_ID"
else
    VFIO_IDS="$GPU_ID"
fi

# Step 2: Write the configuration file
VFIO_CONF="/etc/modprobe.d/vfio.conf"
echo ">> Writing isolation rules to $VFIO_CONF..."

echo "options vfio-pci ids=$VFIO_IDS disable_vga=1" > "$VFIO_CONF"
echo "softdep amdgpu pre: vfio-pci" >> "$VFIO_CONF"

# Step 3: Update Initramfs so the kernel knows at boot time
echo ">> Rebuilding initramfs (This takes about 30-60 seconds)..."
update-initramfs -u -k all

echo "========================================================"
echo "🎉 SUCCESS: The AMD GPU ($VFIO_IDS) is now isolated!"
echo "⚠️  You must REBOOT the Proxmox server for this to take effect."
echo "========================================================"
