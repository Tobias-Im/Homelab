#!/bin/bash
# Full Homelab backup into a single archive
# ------------------------------------------

# CONFIGURATION
DOCKER_DIR="$HOME/wall/Docker"
BACKUP_DIR="$HOME/wall/BackUp"   # <- updated backup location
TIMESTAMP=$(date +%F_%H-%M-%S)
ARCHIVE_NAME="$BACKUP_DIR/homelab-full-backup-$TIMESTAMP.tar.gz"

# Create backup folder if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Temporary folder to assemble backup
TMP_BACKUP="$HOME/homelab-tmp-backup-$TIMESTAMP"
mkdir -p "$TMP_BACKUP"/{bindmounts,volumes,compose,secrets,scripts,system_configs,rclone}

echo "Creating temporary backup folder: $TMP_BACKUP"

# -------------------------------
# 0. Stop Docker Containers to ensure data consistency
# -------------------------------
echo "Stopping Docker containers to prevent database/config corruption..."
cd "$DOCKER_DIR" && docker compose down


# -------------------------------
# 1. Backup docker-compose.yml and .env
# -------------------------------
[[ -f "$DOCKER_DIR/docker-compose.yml" ]] && cp "$DOCKER_DIR/docker-compose.yml" "$TMP_BACKUP/compose/"
[[ -f "$DOCKER_DIR/.env" ]] && cp "$DOCKER_DIR/.env" "$TMP_BACKUP/compose/"

# -------------------------------
# 2. Backup all bind-mounted folders
# -------------------------------
for folder in "$DOCKER_DIR"/*/; do
  folder_name=$(basename "$folder")
  # Use an Alpine container to bypass root-permission errors (e.g. Crowdsec files)
  docker run --rm -v "$DOCKER_DIR":/docker_data -v "$TMP_BACKUP/bindmounts":/backup alpine \
    tar czf "/backup/${folder_name}.tar.gz" -C /docker_data "$folder_name"
  echo "Backed up bind mount: $folder_name"
done

# -------------------------------
# 3. Backup all Docker volumes
# -------------------------------
docker volume ls -q | while read volume; do
  docker run --rm -v ${volume}:/vol -v "$TMP_BACKUP/volumes":/backup alpine \
    tar czf /backup/${volume}.tar.gz -C /vol .
  echo "Backed up volume: $volume"
done

# -------------------------------
# 3.5. Backup Custom Scripts
# -------------------------------
if [[ -d "$HOME/wall/Scripts" ]]; then
  cp -a "$HOME/wall/Scripts" "$TMP_BACKUP/scripts/"
  echo "Backed up custom scripts"
fi

# -------------------------------
# 3.6. Backup rclone configuration
# -------------------------------
if [[ -d "$HOME/.config/rclone" ]]; then
  cp -a "$HOME/.config/rclone" "$TMP_BACKUP/rclone/"
  echo "Backed up rclone configuration"
fi

# -------------------------------
# 3.7. Backup System Configs (Reference Only)
# -------------------------------
# These files are backed up for safekeeping/reference only. 
# They are explicitly NOT restored by the restore script because Ansible builds them from scratch!
cp /etc/fstab "$TMP_BACKUP/system_configs/fstab.bak" 2>/dev/null
cp /etc/cron.d/homeassistant_cron "$TMP_BACKUP/system_configs/homeassistant_cron.bak" 2>/dev/null
if [[ -d "$HOME/.ssh" ]]; then
  cp -a "$HOME/.ssh" "$TMP_BACKUP/system_configs/ssh_keys"
fi
echo "Backed up system configs (fstab, cron, ssh) for reference"

# -------------------------------
# 4. Create final archive
# -------------------------------
tar -czvf "$ARCHIVE_NAME" -C "$TMP_BACKUP" .
echo "[OK] Backup completed!"

# -------------------------------
# 5. Restart Docker Containers
# -------------------------------
echo "Restarting Docker containers..."
cd "$DOCKER_DIR" && docker compose up -d
echo "Archive file: $ARCHIVE_NAME"

# -------------------------------
# 6. Cleanup temporary folder
# -------------------------------
rm -rf "$TMP_BACKUP"
echo "Temporary backup folder removed: $TMP_BACKUP"
