#!/bin/bash

# ==============================================================================
# HARDEN SSH SERVER CONFIGURATION
# ==============================================================================
# Disables root login and empty passwords, but retains password authentication
# so you can log in without needing an SSH key.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 HARDENING SSH SECURITY"
echo "========================================================"

SSHD_CONFIG="/etc/ssh/sshd_config"

echo ">> Backing up original sshd_config..."
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

echo ">> Applying security settings..."

# 1. Disable root login (Hackers can no longer try to guess the root password)
# We find any line starting with PermitRootLogin (even if commented out) and replace it.
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
# If it didn't exist at all, append it
if ! grep -q "^PermitRootLogin no" "$SSHD_CONFIG"; then
    echo "PermitRootLogin no" >> "$SSHD_CONFIG"
fi

# 2. Prevent empty passwords
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"
if ! grep -q "^PermitEmptyPasswords no" "$SSHD_CONFIG"; then
    echo "PermitEmptyPasswords no" >> "$SSHD_CONFIG"
fi

# 3. Explicitly ALLOW Password Authentication (As you requested)
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
if ! grep -q "^PasswordAuthentication yes" "$SSHD_CONFIG"; then
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi

sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' "$SSHD_CONFIG"
if ! grep -q "^KbdInteractiveAuthentication yes" "$SSHD_CONFIG"; then
    echo "KbdInteractiveAuthentication yes" >> "$SSHD_CONFIG"
fi

echo ">> Restarting SSH service..."
systemctl restart ssh
# On some Debian variants the service is sshd, on others it is ssh. We run both to be safe.
systemctl restart sshd 2>/dev/null || true

echo "========================================================"
echo "🎉 SUCCESS: SSH is now hardened!"
echo "   - Root login is DISABLED. (You must log in as Saturday)"
echo "   - Empty passwords are DISABLED."
echo "   - Password logins are ALLOWED (No SSH key required)."
echo "========================================================"
