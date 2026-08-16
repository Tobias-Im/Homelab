#!/bin/bash
# Full Monitoring Server Backup
# ------------------------------------------

# CONFIGURATION
DOCKER_DIR="$HOME/docker"
WAZUH_DIR="$DOCKER_DIR/wazuh-docker/single-node"
BACKUP_DIR="$HOME/BackUp"
TIMESTAMP=$(date +%F_%H-%M-%S)
ARCHIVE_NAME="$BACKUP_DIR/monitoring-full-backup-$TIMESTAMP.tar.gz"

# Create backup folder if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Temporary folder to assemble backup
TMP_BACKUP="$HOME/monitoring-tmp-backup-$TIMESTAMP"
mkdir -p "$TMP_BACKUP"/{docker_dir,volumes,system_configs}

echo "Creating temporary backup folder: $TMP_BACKUP"

# -------------------------------
# 0. Stop Docker Containers to ensure data consistency
# -------------------------------
echo "Stopping Wazuh SIEM Stack..."
cd "$WAZUH_DIR" && docker compose down 2>/dev/null || true

echo "Stopping Main Monitoring Stack..."
cd "$DOCKER_DIR" && docker compose -f docker-compose-monitoring.yml down 2>/dev/null || true

# -------------------------------
# 1. Backup entire Docker directory (bind mounts, configs, compose files)
# -------------------------------
echo "Backing up Docker directory..."
docker run --rm -v "$HOME/docker":/docker_data -v "$TMP_BACKUP/docker_dir":/backup alpine \
  tar czf /backup/docker_folder.tar.gz -C /docker_data .
echo "Backed up docker directory"

# -------------------------------
# 1.5. Backup Custom Scripts
# -------------------------------
if [[ -d "$HOME/Scripts" ]]; then
  echo "Backing up custom scripts..."
  cp -a "$HOME/Scripts" "$TMP_BACKUP/scripts"
  echo "Backed up custom scripts"
fi

# -------------------------------
# 2. Backup all Docker volumes
# -------------------------------
echo "Backing up Docker volumes..."
docker volume ls -q | while read volume; do
  docker run --rm -v "${volume}":/vol -v "$TMP_BACKUP/volumes":/backup alpine \
    tar czf /backup/"${volume}".tar.gz -C /vol .
  echo "Backed up volume: $volume"
done

# -------------------------------
# 3. Backup System Configs (fstab, cron, ssh)
# -------------------------------
echo "Backing up system configs..."
mkdir -p "$TMP_BACKUP/system_configs/cron"
cp /etc/fstab "$TMP_BACKUP/system_configs/fstab.bak" 2>/dev/null || true
cp -a /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly /etc/cron.yearly "$TMP_BACKUP/system_configs/cron/" 2>/dev/null || true

if [[ -d "$HOME/.ssh" ]]; then
  cp -a "$HOME/.ssh" "$TMP_BACKUP/system_configs/ssh_keys"
fi
echo "Backed up system configs & SSH keys"

# -------------------------------
# 4. Create final archive
# -------------------------------
echo "Creating final archive..."
tar -czvf "$ARCHIVE_NAME" -C "$TMP_BACKUP" .
echo "[OK] Backup completed!"

# -------------------------------
# 5. Restart Docker Containers
# -------------------------------
echo "Starting Wazuh SIEM Stack..."
cd "$WAZUH_DIR" && docker compose up -d

echo "Starting Main Monitoring Stack..."
cd "$DOCKER_DIR" && docker compose -f docker-compose-monitoring.yml up -d

# -------------------------------
# 6. Cleanup temporary folder
# -------------------------------
rm -rf "$TMP_BACKUP"
echo "Temporary backup folder removed: $TMP_BACKUP"
echo "Archive file: $ARCHIVE_NAME"
