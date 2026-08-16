#!/bin/bash
# ==============================================================================
# Script: proxmox_create_terraform_token.sh
# Description: Forcefully injects a hardcoded Proxmox API token and its 
#              permissions directly into the Proxmox cluster configuration files,
#              allowing zero-touch restoration without updating Terraform.
# ==============================================================================

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "====================================================================="
echo " Forcibly injecting hardcoded Terraform API Token into Proxmox..."
echo "====================================================================="

# Target Configuration Files
USER_CFG="/etc/pve/user.cfg"
TOKEN_CFG="/etc/pve/priv/token.cfg"

# Desired Data
TOKEN_ENTRY="token:root@pam!terraform:0:1::"
ACL_ENTRY="acl:1:/:root@pam!terraform:Administrator:"
SECRET_ENTRY="root@pam!terraform <YOUR_PROXMOX_API_TOKEN>"

# 1. Inject Public Data (user.cfg)
if grep -q "root@pam!terraform" "$USER_CFG"; then
    echo "⚠️ Token already exists in $USER_CFG. Skipping injection to prevent duplicates."
else
    echo ">> Injecting Token ID and ACLs into $USER_CFG..."
    echo "$TOKEN_ENTRY" >> "$USER_CFG"
    echo "$ACL_ENTRY" >> "$USER_CFG"
fi

# 2. Inject Private Secret (token.cfg)
if [ ! -f "$TOKEN_CFG" ]; then
    echo ">> Creating $TOKEN_CFG because it doesn't exist yet..."
    touch "$TOKEN_CFG"
    chmod 0600 "$TOKEN_CFG"
fi

if grep -q "root@pam!terraform" "$TOKEN_CFG"; then
    echo "⚠️ Secret already exists in $TOKEN_CFG. Skipping injection."
else
    echo ">> Forcibly injecting plaintext secret into $TOKEN_CFG..."
    echo "$SECRET_ENTRY" >> "$TOKEN_CFG"
fi

echo ""
echo "✅ SUCCESS! Hardcoded Terraform Token successfully injected."
echo "Your Terraform pipeline will now authenticate perfectly using your injected secret!"
echo "====================================================================="
