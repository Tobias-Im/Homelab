#!/bin/bash

# Configuration
BACKUP_DIR="/home/Saturday/wall/BackUp"
RCLONE_REMOTE="mycloud:HomelabBackups"

echo "================================================="
echo "   Starting Cloud Upload to Google Drive..."
echo "================================================="

# Find the single newest .tar.gz file for both servers
LATEST_HOMELAB=$(ls -t "$BACKUP_DIR"/homelab-full-backup-*.tar.gz 2>/dev/null | head -n 1)
LATEST_MONITORING=$(ls -t "$BACKUP_DIR"/monitoring-full-backup-*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$LATEST_HOMELAB" ] && [ -z "$LATEST_MONITORING" ]; then
    echo "[X] Error: No backup archives found in $BACKUP_DIR"
    exit 1
fi

# 1. Clean up OLD backups FIRST to make room!
echo "Cleaning up old backups from Google Drive (Deleting all previous backups) before uploading..."

# Clean up Homelab backups
rclone lsf "$RCLONE_REMOTE" | grep '^homelab-full-backup-.*\.tar\.gz$' | while read -r file; do
    echo "Deleting old Homelab cloud backup: $file"
    rclone deletefile "$RCLONE_REMOTE/$file" --drive-use-trash=false
done

# Clean up Monitoring backups
rclone lsf "$RCLONE_REMOTE" | grep '^monitoring-full-backup-.*\.tar\.gz$' | while read -r file; do
    echo "Deleting old Monitoring cloud backup: $file"
    rclone deletefile "$RCLONE_REMOTE/$file" --drive-use-trash=false
done

echo "[OK] Cloud cleanup complete! Space has been cleared."

# 2. Now upload the new backups!
UPLOAD_SUCCESS=true

if [ -n "$LATEST_HOMELAB" ]; then
    echo "[START] Uploading $(basename "$LATEST_HOMELAB") to Google Drive..."
    rclone copy "$LATEST_HOMELAB" "$RCLONE_REMOTE" --progress --ignore-existing --drive-chunk-size 128M --timeout 10m
    if [ $? -ne 0 ]; then UPLOAD_SUCCESS=false; fi
fi

if [ -n "$LATEST_MONITORING" ]; then
    echo "[START] Uploading $(basename "$LATEST_MONITORING") to Google Drive..."
    rclone copy "$LATEST_MONITORING" "$RCLONE_REMOTE" --progress --ignore-existing --drive-chunk-size 128M --timeout 10m
    if [ $? -ne 0 ]; then UPLOAD_SUCCESS=false; fi
fi

if [ "$UPLOAD_SUCCESS" = true ]; then
    echo "[OK] All uploads completed successfully!"
else
    echo "[X] Error: One or more uploads failed. Please check rclone configuration."
    exit 1
fi
