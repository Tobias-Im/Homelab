#!/bin/bash

# ==============================================================================
# FAIL2BAN INSTALLER & CONFIGURATOR
# ==============================================================================
# Installs Fail2Ban and configures it to protect the SSH port from brute-force
# attacks. Automatically whitelists local home networks to prevent lockouts.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING FAIL2BAN SECURITY"
echo "========================================================"

# Step 1: Install Fail2Ban
echo ">> Updating packages..."
apt-get update >/dev/null 2>&1

echo ">> Installing fail2ban..."
DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban

# Step 2: Configure Jail.local
JAIL_FILE="/etc/fail2ban/jail.local"
echo ">> Configuring security rules in $JAIL_FILE..."

# We create a local config instead of editing jail.conf directly, 
# because jail.conf gets overwritten during software updates.
cat <<EOF > "$JAIL_FILE"
[DEFAULT]
# Whitelist localhost and all standard private home networks (Extremely important!)
ignoreip = 127.0.0.1/8 ::1 192.168.X.X/16 10.0.0.0/8 172.16.0.0/12

# Ban time in seconds (1 hour = 3600)
bantime  = 3600

# A host is banned if it fails 'maxretry' times during the last 'findtime' window (300s = 5 mins)
findtime  = 300
maxretry = 4

[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 4
EOF

# Step 3: Restart and Enable
echo ">> Restarting Fail2Ban service..."
systemctl restart fail2ban
systemctl enable fail2ban

echo "========================================================"
echo "🎉 SUCCESS: Fail2Ban is now actively protecting this machine!"
echo "   - Hackers will be banned for 1 hour after 4 failed attempts."
echo "   - Your local home network (192.168.x.x) is completely whitelisted."
echo "========================================================"
