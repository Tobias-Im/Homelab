#!/bin/bash
# Restore Monitoring Server from a single backup archive
# --------------------------------------------

# CONFIGURATION
DOCKER_DIR="/home/Saturday/docker"
WAZUH_DIR="$DOCKER_DIR/wazuh-docker/single-node"
BACKUP_DIR="/home/Saturday/BackUp"
ARCHIVE=$(ls -t "$BACKUP_DIR"/monitoring-full-backup-*.tar.gz 2>/dev/null | head -n 1)  # latest backup
TMP_RESTORE="/home/Saturday/monitoring-restore-tmp"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "[X] Backup archive not found in $BACKUP_DIR"
  exit 1
fi

echo "Using backup archive: $ARCHIVE"

# Create temp restore folder
mkdir -p "$TMP_RESTORE"
echo "Extracting backup..."
tar -xzf "$ARCHIVE" -C "$TMP_RESTORE"

# -------------------------------
# 0. Stop Docker Containers before restoring over them
# -------------------------------
if [[ -d "$WAZUH_DIR" ]]; then
  echo "Stopping Wazuh SIEM Stack..."
  cd "$WAZUH_DIR" && docker compose down 2>/dev/null || true
fi

if [[ -d "$DOCKER_DIR" ]]; then
  echo "Stopping Main Monitoring Stack..."
  cd "$DOCKER_DIR" && docker compose -f docker-compose-monitoring.yml down 2>/dev/null || true
fi

# -------------------------------
# 1. Restore Docker directory (bind mounts, configs, compose files)
# -------------------------------
mkdir -p "$DOCKER_DIR"
if [[ -f "$TMP_RESTORE/docker_dir/docker_folder.tar.gz" ]]; then
  echo "Restoring Docker directory (Using Alpine Container to handle root certificates)..."
  docker run --rm -v "$DOCKER_DIR":/docker_data -v "$TMP_RESTORE/docker_dir":/backup alpine \
    tar xzf /backup/docker_folder.tar.gz -C /docker_data
  echo "Restored docker directory"
fi

# -------------------------------
# 2. Restore Docker volumes
# -------------------------------
if [[ -d "$TMP_RESTORE/volumes" ]]; then
  echo "Restoring Docker volumes..."
  for f in "$TMP_RESTORE/volumes/"*.tar.gz; do
    volume_name=$(basename "$f" .tar.gz)
    docker volume create "$volume_name"
    docker run --rm -v "$volume_name":/vol -v "$TMP_RESTORE/volumes":/backup alpine \
      tar xzf /backup/$(basename "$f") -C /vol
    echo "Restored volume: $volume_name"
  done
fi

# -------------------------------
# 3. Restore Custom Scripts
# -------------------------------
if [[ -d "$TMP_RESTORE/scripts" ]]; then
  mkdir -p "/home/Saturday/Scripts"
  cp -a "$TMP_RESTORE/scripts/." "/home/Saturday/Scripts/"
  echo "Custom scripts restored"
fi

# -------------------------------
# 3.5. Restore SSH Keys
# -------------------------------
if [[ -d "$TMP_RESTORE/system_configs/ssh_keys" ]]; then
  echo "Restoring SSH keys..."
  mkdir -p "$HOME/.ssh"
  cp -a "$TMP_RESTORE/system_configs/ssh_keys/." "$HOME/.ssh/"
  chmod 700 "$HOME/.ssh"
  chmod 600 "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/authorized_keys" 2>/dev/null || true
  chmod 644 "$HOME/.ssh/"*.pub 2>/dev/null || true
  echo "SSH keys restored"
fi

# -------------------------------
# 4. Cleanup
# -------------------------------
rm -rf "$TMP_RESTORE"
echo "Temporary restore folder removed: $TMP_RESTORE"

# -------------------------------
# 5. Start Docker stack
# -------------------------------
echo "Starting Wazuh SIEM Stack..."
cd "$WAZUH_DIR" && docker compose up -d

echo "Starting Main Monitoring Stack..."
cd "$DOCKER_DIR" && docker compose -f docker-compose-monitoring.yml up -d

echo "[OK] Monitoring Server restored and started successfully!"
