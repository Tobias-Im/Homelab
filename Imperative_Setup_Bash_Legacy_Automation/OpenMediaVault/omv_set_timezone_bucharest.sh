#!/bin/bash

# ==============================================================================
# SET SYSTEM TIMEZONE
# ==============================================================================
# Configures the server's timezone to Europe/Bucharest.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 CONFIGURING TIMEZONE (BUCHAREST)"
echo "========================================================"

echo ">> Current timezone:"
timedatectl | grep "Time zone"

echo ">> Changing timezone to Europe/Bucharest..."
timedatectl set-timezone Europe/Bucharest

# Restart systemd-timesyncd to immediately sync the new time
systemctl restart systemd-timesyncd 2>/dev/null || true

echo ">> New timezone:"
timedatectl | grep "Time zone"

echo "✅ Success! Timezone updated."
echo "👉 Note: If the OpenMediaVault Web GUI still shows 'America', simply go to System -> Date & Time in the GUI and hit save to sync the database."
