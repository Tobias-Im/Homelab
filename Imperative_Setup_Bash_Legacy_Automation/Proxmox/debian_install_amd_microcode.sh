#!/bin/bash

# ==============================================================================
# AMD CPU MICROCODE UPDATER
# ==============================================================================
# This script installs the latest CPU microcode patches from AMD. 
# Microcode updates are critical for system stability, optimal performance, 
# and patching low-level hardware security flaws (like Spectre/Meltdown).
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING AMD CPU MICROCODE"
echo "========================================================"

# Update the package lists to ensure we pull the latest version
echo ">> Updating apt repositories..."
apt update

# Install the microcode package silently (non-interactive)
echo ">> Installing 'amd64-microcode'..."
DEBIAN_FRONTEND=noninteractive apt install -y amd64-microcode

# Verify installation was successful
# $? holds the exit code of the last command (0 = success)
if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "✅ Success! AMD Microcode is installed."
    echo "👉 Note: Microcode patches are applied by the kernel at boot."
    echo "         You MUST REBOOT the server to activate the update."
else
    echo "--------------------------------------------------------"
    echo "❌ Error: Failed to install amd64-microcode."
fi
