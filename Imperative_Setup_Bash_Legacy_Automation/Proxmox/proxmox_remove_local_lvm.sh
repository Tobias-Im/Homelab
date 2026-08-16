#!/bin/bash

# ==============================================================================
# PROXMOX STORAGE CONSOLIDATOR (REMOVE LOCAL-LVM)
# ==============================================================================
# This script removes the 'local-lvm' storage, deletes the underlying thin pool,
# and extends the 'local' (root) storage to use all available disk space.
#
# WARNING: THIS WILL DESTROY ALL DATA ON 'local-lvm'.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

# 2. SAFETY WARNING
echo "========================================================================"
echo "⚠️  DANGER: DATA DESTRUCTION WARNING"
echo "========================================================================"
echo "This script will PERMANENTLY DELETE the 'local-lvm' storage."
echo "Any Virtual Machines or Containers currently stored there will be LOST."
echo "Your 'local' storage will then be expanded to fill the disk."
echo ""

echo "-----------------------------------------------------"
echo "Step 1: Removing 'local-lvm' from Proxmox configuration..."
# We use '|| true' to prevent the script from stopping if it's already removed
pvesm remove local-lvm || echo "   (Storage 'local-lvm' not found in config, skipping)"

echo "-----------------------------------------------------"
echo "Step 2: Configuring 'local' to support all content types..."
# This allows 'local' to store Disk Images and Containers, not just ISOs/Backups
# Correct, official Proxmox content types
pvesm set local --content backup,images,import,iso,rootdir,snippets,vztmpl

echo "-----------------------------------------------------"
echo "Step 3: Removing the LVM-Thin Pool (/dev/pve/data)..."
if [ -e "/dev/pve/data" ]; then
    lvremove -y /dev/pve/data
    echo "   ✅ Logical Volume 'data' removed."
else
    echo "   (Logical Volume 'data' already missing, skipping)"
fi

echo "-----------------------------------------------------"
echo "Step 4: Extending the Root Logical Volume..."
# -l +100%FREE tells lvm to use all the free space we just freed up
lvresize -l +100%FREE /dev/pve/root

echo "-----------------------------------------------------"
echo "Step 5: Resizing the Filesystem..."
# This makes the file system aware of the new space immediately (online resize)
resize2fs /dev/mapper/pve-root

echo "-----------------------------------------------------"
echo "🎉 Success! Storage consolidated."
echo "   New Storage Status:"
echo "-----------------------------------------------------"
df -h /