#!/bin/bash
# monitoring_cleanup_backups.sh
# Retain only the 1 most recent backup archive

BACKUP_DIR="/home/Saturday/BackUp"

echo "================================================="
echo "   Starting Local Backup Cleanup (Monitoring)..."
echo "================================================="

cd "$BACKUP_DIR" || exit 1

# Count how many archives exist
ARCHIVE_COUNT=$(ls -1 *.tar.gz 2>/dev/null | wc -l)

if [ "$ARCHIVE_COUNT" -le 1 ]; then
    echo "[OK] Only $ARCHIVE_COUNT backups found. No cleanup needed."
    exit 0
fi

echo "Found $ARCHIVE_COUNT backups. Retaining the 1 newest, deleting the rest..."

# List files sorted by modification time (newest first), skip the first 1, and delete the rest
ls -t *.tar.gz 2>/dev/null | tail -n +2 | while read -r file; do
    echo "Deleting old backup: $file"
    rm -f "$file"
done

echo "[OK] Cleanup complete! Only the 1 most recent backup remains."
