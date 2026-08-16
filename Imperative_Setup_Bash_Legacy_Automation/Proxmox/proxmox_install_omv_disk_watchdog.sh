#!/bin/bash

# ==============================================================================
# INSTALL OMV DISK WATCHDOG TO CRONTAB
# ==============================================================================
# Copies the auto-attach daemon to a system path and registers it in crontab.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

DAEMON_SOURCE="./proxmox_auto_attach_omv_disk.sh"
DAEMON_DEST="/usr/local/bin/proxmox_auto_attach_omv_disk.sh"
CRON_JOB="* * * * * $DAEMON_DEST"

echo "--------------------------------------------------------"
echo "🚀 INSTALLING OMV DISK WATCHDOG"
echo "--------------------------------------------------------"

if [ ! -f "$DAEMON_SOURCE" ]; then
    echo "❌ Error: Could not find $DAEMON_SOURCE in the current directory."
    exit 1
fi

# 1. Copy script to a safe system path and make executable
echo ">> Copying daemon to $DAEMON_DEST..."
cp "$DAEMON_SOURCE" "$DAEMON_DEST"
chmod +x "$DAEMON_DEST"

# 2. Add to crontab if not already there
echo ">> Configuring crontab..."
if crontab -l 2>/dev/null | grep -Fq "$DAEMON_DEST"; then
    echo ">> Watchdog is already installed in crontab. Skipping."
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo ">> Added watchdog to crontab to run every minute!"
fi

echo "🎉 SUCCESS: OMV Disk Watchdog is active!"
