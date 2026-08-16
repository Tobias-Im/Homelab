#!/bin/bash
# monitoring_transfer_to_homelab.sh
# Transfer the latest Monitoring backup to the Homelab server for centralized storage

BACKUP_DIR="/home/Saturday/BackUp"
DEST_SERVER="Saturday@Homelab"
DEST_DIR="/home/Saturday/wall/BackUp"

echo "================================================="
echo "   Starting Transfer to Homelab Server..."
echo "================================================="

# Find the single newest .tar.gz file in the backup directory
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "[X] Error: No backup archives found in $BACKUP_DIR"
    exit 1
fi

echo "[OK] Found latest backup: $(basename "$LATEST_BACKUP")"
echo "Transferring to $DEST_SERVER:$DEST_DIR ..."

# Use scp to transfer the file
scp -o StrictHostKeyChecking=no "$LATEST_BACKUP" "$DEST_SERVER:$DEST_DIR/"

if [ $? -eq 0 ]; then
    echo "[OK] Transfer completed successfully!"
else
    echo "[X] Error: Transfer failed. Please check SSH keys and network connection."
    exit 1
fi
