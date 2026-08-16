#!/bin/bash

# ==============================================================================
# PROXMOX BACKUP SERVER (PBS) INSTALLER & MOUNT MANAGER
# ==============================================================================
# This script installs PBS alongside Proxmox VE. 
# It expects an external HDD to be pre-formatted as ext4 with the label 'PBS_BACKUPS'.
# This allows the script to be run on fresh installs without wiping existing backups!

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

echo "=========================================================="
echo "🚀 Installing Proxmox Backup Server (PBS)..."
echo "=========================================================="

MOUNT_POINT="/mnt/PBS_Backups"
FSTAB_ENTRY="LABEL=PBS_BACKUPS $MOUNT_POINT ext4 defaults,nofail 0 2"
DATASTORE_NAME="WD_Backups"

# 1. Setup Mount Point
if [ ! -d "$MOUNT_POINT" ]; then
    echo "📁 Creating mount point $MOUNT_POINT..."
    mkdir -p "$MOUNT_POINT"
fi

# 2. Add to fstab if not exists
if ! grep -q "LABEL=PBS_BACKUPS" /etc/fstab; then
    echo "📝 Adding drive to /etc/fstab for permanent mounting by LABEL..."
    echo "$FSTAB_ENTRY" >> /etc/fstab
    systemctl daemon-reload
else
    echo "✅ Drive already configured in /etc/fstab."
fi

# 3. Mount the drive
echo "🔄 Mounting the backup drive..."
mount -a

# Ensure the drive actually mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "❌ ERROR: Failed to mount the backup drive!"
    echo "   Did you format it to ext4 and name the label 'PBS_BACKUPS'?"
    exit 1
fi

# 4. Install Proxmox Backup Server
echo "📦 Adding PBS No-Subscription Repository..."
echo "deb http://download.proxmox.com/debian/pbs trixie pbs-no-subscription" > /etc/apt/sources.list.d/pbs-no-subscription.list
rm -f /etc/apt/sources.list.d/*enterprise*
sed -i '/enterprise.proxmox.com/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null
echo "📦 Installing proxmox-backup-server package..."
apt-get update -qq
apt-get install -y proxmox-backup-server jq

# 5. Set Ownership for PBS
echo "🔐 Setting permissions for the 'backup' system user..."
chown -R backup:backup "$MOUNT_POINT"

# 6. Initialize or Re-Adopt PBS Datastore
if ! proxmox-backup-manager datastore list | grep -q "$DATASTORE_NAME"; then
    echo "⚙️  Adding Datastore '$DATASTORE_NAME' to PBS configuration..."
    proxmox-backup-manager datastore create "$DATASTORE_NAME" "$MOUNT_POINT"
else
    echo "✅ Datastore '$DATASTORE_NAME' is already configured in PBS."
fi

# 7. Configure Retention Policy (Prune Job)
if ! proxmox-backup-manager prune-job list | grep -q "prune-wd"; then
    echo "🧹 Configuring Retention Policy (7 Daily, 4 Weekly, 3 Monthly)..."
    proxmox-backup-manager prune-job create prune-wd --store "$DATASTORE_NAME" \
        --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --schedule daily
else
    echo "✅ Retention Policy is already configured."
fi

# 8. Link Proxmox VE to Proxmox Backup Server (Autonomous API Token)
if ! pvesm status | grep -q "PBS_Storage"; then
    echo "🔗 Linking Proxmox VE to Backup Server autonomously..."
    
    # If the token already exists, delete it so we can generate a fresh one to grab the secret
    if proxmox-backup-manager user list-tokens root@pam | grep -q "pve-link"; then
        proxmox-backup-manager user delete-token root@pam pve-link
    fi

    # Generate a fresh API token and parse the secret
    TOKEN_OUTPUT=$(proxmox-backup-manager user generate-token root@pam pve-link)
    
    # Try multiple ways to parse the secret
    PBS_SECRET=$(echo "$TOKEN_OUTPUT" | grep -ioE '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')
    if [ -z "$PBS_SECRET" ]; then
        PBS_SECRET=$(echo "$TOKEN_OUTPUT" | grep -i "value" | awk '{print $4}')
    fi
    
    # Get the PBS server fingerprint (extracts exactly the 32-byte hex string)
    FINGERPRINT=$(proxmox-backup-manager cert info | grep -ioE '([0-9a-fA-F]{2}:){31}[0-9a-fA-F]{2}')
    
    # Grant the API Token permission to actually see the Datastore
    proxmox-backup-manager acl update /datastore/"$DATASTORE_NAME" DatastoreAdmin --auth-id root@pam!pve-link
    
    # Link it to PVE! We pass the secret using the --password flag
    pvesm add pbs PBS_Storage --server 127.0.0.1 --datastore "$DATASTORE_NAME" \
        --username root@pam!pve-link --password "$PBS_SECRET" --fingerprint "$FINGERPRINT"
    
    echo "✅ Successfully linked Proxmox VE to PBS!"
else
    echo "✅ Proxmox VE is already linked to PBS Storage."
fi

# 9. Automate Nightly VM Backups to PBS (2:00 AM)
if ! grep -q "PBS_Storage" /etc/pve/jobs.cfg 2>/dev/null; then
    echo "🌙 Scheduling automated nightly backups for ALL Virtual Machines at 2:00 AM..."
    echo "" >> /etc/pve/jobs.cfg
    echo "vzdump: backup-all-pbs" >> /etc/pve/jobs.cfg
    echo "	schedule 02:00" >> /etc/pve/jobs.cfg
    echo "	all 1" >> /etc/pve/jobs.cfg
    echo "	mode snapshot" >> /etc/pve/jobs.cfg
    echo "	storage PBS_Storage" >> /etc/pve/jobs.cfg
    echo "	enabled 1" >> /etc/pve/jobs.cfg
    echo "	notes-template {{guestname}}" >> /etc/pve/jobs.cfg
    
    echo "✅ Nightly Backup Schedule created!"
else
    echo "✅ Nightly Backup Schedule is already configured."
fi

echo "=========================================================="
echo "🎉 Proxmox Backup Server Installation Complete!"
echo "🌐 Accessible at: https://$(hostname -I | awk '{print $1}'):8007"
echo "=========================================================="
