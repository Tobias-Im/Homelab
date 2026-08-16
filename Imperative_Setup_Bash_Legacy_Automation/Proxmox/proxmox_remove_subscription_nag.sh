#!/bin/bash

# ==============================================================================
# PROXMOX REMOVE SUBSCRIPTION NAG
# ==============================================================================
# This script removes the "No valid subscription" popup that appears every time
# you log into the Proxmox Web GUI using the free repositories.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 REMOVING PROXMOX SUBSCRIPTION NAG"
echo "========================================================"

# The file that controls the login popup
FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

# 1. Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "❌ Error: Cannot find $FILE. Is this a Proxmox server?"
    exit 1
fi

# 2. Create a backup (Idempotent: only if backup doesn't already exist)
if [ ! -f "${FILE}.bak" ]; then
    echo ">> Creating backup of proxmoxlib.js..."
    cp "$FILE" "${FILE}.bak"
else
    echo ">> Backup already exists, skipping backup creation."
fi

# 3. Apply the patch
# We search for the specific validation function and bypass it.
# This handles both Proxmox 7.x and Proxmox 8.x javascript syntax.
echo ">> Patching proxmoxlib.js..."

# Proxmox 8.x syntax
sed -i.bak "s/res.data.status.toLowerCase() !== 'active'/false/g" "$FILE"

# Proxmox 7.x syntax (Legacy)
sed -i "s/res.status !== 'Active'/false/g" "$FILE"

# 4. Restart the web service so the changes take effect
echo ">> Restarting Proxmox web service (pveproxy)..."
systemctl restart pveproxy

echo "✅ Success! The subscription nag has been removed."
echo "👉 Note: You MUST clear your browser cache (CTRL+F5) to see the change."
