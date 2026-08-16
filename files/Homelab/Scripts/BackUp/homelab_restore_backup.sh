#!/bin/bash
# Restore Homelab from a single backup archive
# --------------------------------------------

# CONFIGURATION
DOCKER_DIR="$HOME/wall/Docker"
BACKUP_DIR="$HOME/wall/BackUp"
ARCHIVE=$(ls -t "$BACKUP_DIR"/homelab-full-backup-*.tar.gz | head -n 1)  # latest backup
TMP_RESTORE="$HOME/homelab-restore-tmp"

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
if [[ -d "$DOCKER_DIR" ]]; then
  echo "Stopping running containers before overwriting data..."
  cd "$DOCKER_DIR" && docker compose down 2>/dev/null || true
fi

# -------------------------------
# 1. Restore bind-mounted folders
# -------------------------------
mkdir -p "$DOCKER_DIR"
for f in "$TMP_RESTORE/bindmounts/"*.tar.gz; do
  folder_name=$(basename "$f" .tar.gz)
  # Use Alpine container to bypass root-permission errors when writing files
  docker run --rm -v "$DOCKER_DIR":/docker_data -v "$TMP_RESTORE/bindmounts":/backup alpine \
    tar xzf "/backup/$(basename "$f")" -C /docker_data
  echo "Restored bind mount: $folder_name"
done

# -------------------------------
# 2. Restore Docker volumes
# -------------------------------
for f in "$TMP_RESTORE/volumes/"*.tar.gz; do
  volume_name=$(basename "$f" .tar.gz)
  docker volume create "$volume_name"
  docker run --rm -v "$volume_name":/vol -v "$TMP_RESTORE/volumes":/backup alpine \
    tar xzf /backup/$(basename "$f") -C /vol
  echo "Restored volume: $volume_name"
done

# -------------------------------
# 2.5. Restore Custom Scripts
# -------------------------------
if [[ -d "$TMP_RESTORE/scripts" ]]; then
  mkdir -p "$HOME/wall/Scripts"
  cp -a "$TMP_RESTORE/scripts/." "$HOME/wall/Scripts/"
  echo "Custom scripts restored"
fi

# -------------------------------
# 2.6. Restore SSH Keys
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
# 3. Restore docker-compose.yml and .env
# -------------------------------
cp -a "$TMP_RESTORE/compose/". "$DOCKER_DIR/"
echo "docker-compose.yml and .env restored"

# -------------------------------
# 5. Cleanup
# -------------------------------
rm -rf "$TMP_RESTORE"
echo "Temporary restore folder removed: $TMP_RESTORE"

# -------------------------------
# 6. Start Docker stack
# -------------------------------
cd "$DOCKER_DIR"
docker compose up -d
echo "[OK] Homelab restored and started successfully!"
