#!/bin/bash

# ==============================================================================
# QEMU GUEST AGENT INSTALLER (DEBIAN VM)
# ==============================================================================
# Installs the QEMU Guest Agent inside the VM so Proxmox can communicate with it.
# This enables graceful shutdowns and IP address visibility in the Proxmox UI.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING QEMU GUEST AGENT"
echo "========================================================"

# Step 1: Install the package
echo ">> Updating packages..."
apt-get update >/dev/null 2>&1

echo ">> Installing qemu-guest-agent..."
DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-guest-agent

# Step 2: Enable and start the service
echo ">> Enabling the service to start on boot..."
systemctl enable --now qemu-guest-agent

# Step 3: Check status
if systemctl is-active --quiet qemu-guest-agent; then
    echo "========================================================"
    echo "🎉 SUCCESS: QEMU Guest Agent is installed and running!"
    echo "⚠️  CRITICAL NEXT STEP: "
    echo "    1. Go to the Proxmox Web UI"
    echo "    2. Click on this VM -> Options -> QEMU Guest Agent"
    echo "    3. Double-click it, check the 'Enabled' box, and hit OK."
    echo "    4. Reboot the VM."
    echo "========================================================"
else
    echo "❌ Error: The agent installed, but failed to start."
    echo "   Are you sure 'QEMU Guest Agent' is enabled in the Proxmox VM Options?"
fi
