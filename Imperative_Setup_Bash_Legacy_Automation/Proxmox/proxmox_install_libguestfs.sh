#!/bin/bash
# ==============================================================================
# PROXMOX INSTALL LIBGUESTFS TOOLS
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

echo "========================================================"
echo "🔧 INSTALLING LIBGUESTFS TOOLS"
echo "========================================================"

# Required for modifying Cloud-Init templates with virt-customize
apt update
apt install libguestfs-tools -y

echo "✅ libguestfs-tools installed successfully!"
