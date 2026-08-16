#!/bin/bash

# ==============================================================================
# ENABLE ALL STORAGE CONTENT TYPES
# ==============================================================================
# Ensures Proxmox can store ISOs, Backups, and Containers on the 'local' volume.
# ==============================================================================

# Configuration
STORAGE_ID="local"
# The list below corresponds exactly to the items in your screenshot:
# images   = Disk image
# iso      = ISO image
# vztmpl   = Container template
# backup   = Backup
# rootdir  = Container
# snippets = Snippets
# import   = Import
ALL_CONTENT="backup,images,import,iso,rootdir,snippets,vztmpl"

echo "Enabling ALL content types for storage '$STORAGE_ID'..."

# Execute the Proxmox Storage Manager command
pvesm set $STORAGE_ID --content $ALL_CONTENT

# Verify the changes
if [ $? -eq 0 ]; then
    echo "✅ Success! Storage '$STORAGE_ID' now supports:"
    echo "   $ALL_CONTENT"
    echo ""
    echo "Current Config:"
    grep -A 5 "dir: $STORAGE_ID" /etc/pve/storage.cfg
else
    echo "❌ Error: Failed to update storage configuration."
fi
