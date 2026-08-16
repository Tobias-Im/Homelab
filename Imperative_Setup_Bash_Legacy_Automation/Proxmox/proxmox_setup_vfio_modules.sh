#!/bin/bash

# ==============================================================================
# COMPLETE VFIO MODULE SETUP (PCIe PASSTHROUGH)
# ==============================================================================
# To pass through hardware (like GPUs or Network Cards) to Virtual Machines,
# the Linux kernel needs specific 'vfio' modules loaded into memory at boot time.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 CONFIGURING VFIO KERNEL MODULES"
echo "========================================================"

MODULES_FILE="/etc/modules"
CHANGES_MADE=false

echo ">> Checking $MODULES_FILE for required VFIO modules..."

# Array of required VFIO modules for IOMMU grouping and passthrough
MODULES=(
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
)

# Loop through each module and add it to /etc/modules if it is missing
for MODULE in "${MODULES[@]}"; do
    # grep -q checks if the text exists without printing output
    # ^ means "start of line" to ensure we match the exact module name
    if grep -q "^$MODULE" "$MODULES_FILE"; then
        echo "   ✅ Module '$MODULE' is already configured."
    else
        echo "   ➕ Adding missing module: '$MODULE'"
        echo "$MODULE" >> "$MODULES_FILE"
        CHANGES_MADE=true
    fi
done

echo "--------------------------------------------------------"

# If changes were made, we must rebuild the initial RAM filesystem 
# so the kernel knows about these modules before it even finishes booting.
if [ "$CHANGES_MADE" = true ]; then
    echo ">> Changes were made! Updating initramfs to embed modules..."
    update-initramfs -u -k all
    echo "✅ Success! Please REBOOT your server for changes to take effect."
else
    echo "✅ All VFIO modules were already present. No action needed."
fi
