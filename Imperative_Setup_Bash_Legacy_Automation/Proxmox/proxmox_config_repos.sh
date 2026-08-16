#!/bin/bash

# ==============================================================================
# PROXMOX REPOSITORY CONFIGURATOR (NO-SUBSCRIPTION)
# ==============================================================================
# 1. Removes Enterprise repositories (PVE + Ceph).
# 2. Adds No-Subscription repositories for PVE (Trixie) and Ceph (Squid).
# 3. Holds Ceph packages to prevent accidental installs/upgrades.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================================"
echo "🔧 CONFIGURING PROXMOX REPOSITORIES"
echo "========================================================================"

# ------------------------------------------------------------------------------
# STEP 1: DISABLE ENTERPRISE REPOS
# ------------------------------------------------------------------------------
echo "Step 1: Removing Enterprise repository files..."
rm -vf /etc/apt/sources.list.d/pve-enterprise.sources
rm -vf /etc/apt/sources.list.d/ceph.sources
# Also remove the classic list file if it exists (just in case)
rm -f /etc/apt/sources.list.d/pve-enterprise.list

# ------------------------------------------------------------------------------
# STEP 2: ENABLE PVE NO-SUBSCRIPTION REPO
# ------------------------------------------------------------------------------
# <<: This is the Heredoc operator. It tells the shell: "I am about to give you a block of text right here in the terminal. Keep reading until you see the 'Stop Word'."
# EOF: This is the "Stop Word" (Delimiter). It stands for End Of File. (Note: You can actually type anything here, like END, STOP, or BANANA, as long as the start and end words match).

echo "Step 2: Adding Proxmox VE (Trixie) No-Subscription repository..."
cat <<EOF > /etc/apt/sources.list.d/pve-no-subscription.list
deb http://download.proxmox.com/debian/pve trixie pve-no-subscription
EOF

# ------------------------------------------------------------------------------
# STEP 3: ENABLE CEPH NO-SUBSCRIPTION REPO
# ------------------------------------------------------------------------------
echo "Step 3: Adding Ceph (Squid) No-Subscription repository..."
cat <<EOF > /etc/apt/sources.list.d/ceph-no-subscription.list
deb http://download.proxmox.com/debian/ceph-squid trixie no-subscription
EOF

# ------------------------------------------------------------------------------
# STEP 4: SAFETY LOCK FOR CEPH
# ------------------------------------------------------------------------------
echo "Step 4: Holding Ceph packages to prevent accidental changes..."
# We use 'apt-mark hold' to stop these packages from upgrading automatically
# until you are ready to configure Ceph explicitly. You can undo later with: apt-mark unhold ceph ceph-common ceph-mon ceph-osd ceph-mgr  
apt-mark hold ceph ceph-common ceph-mon ceph-osd ceph-mgr

# ------------------------------------------------------------------------------
# STEP 5: UPDATE LISTS
# ------------------------------------------------------------------------------
echo "Step 5: Updating package lists to apply changes..."
apt update

# ------------------------------------------------------------------------------
# STEP 6: REMOVE 'NO VALID SUBSCRIPTION' UI NAG
# ------------------------------------------------------------------------------
echo "Step 6: Removing the 'No valid subscription' UI popup (Perl API Method)..."
sed -i.bak 's/NotFound/Active/g' /usr/share/perl5/PVE/API2/Subscription.pm
systemctl restart pveproxy.service

echo "========================================================================"
echo "✅ SUCCESS: Repositories configured."
echo "========================================================================"