#!/bin/bash

# ==============================================================================
# PROXMOX CPU GOVERNOR CONFIGURATION (MODERN SYSTEMD METHOD)
# ==============================================================================
# Sets the CPU scaling governor without relying on the deprecated cpufrequtils.
# Options: performance, schedutil (smart balanced), conservative (cool & quiet)
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

# Change this variable to your preferred mode!
# "schedutil" = Smart balanced (Recommended for cool & quiet homelabs)
# "performance" = Max power 24/7 (You requested this!)
GOVERNOR="performance"

echo "========================================================"
echo "🚀 CONFIGURING CPU GOVERNOR: $GOVERNOR"
echo "========================================================"

echo ">> Creating persistent SystemD service for CPU Governor..."

# Create a lightweight systemd service to apply the governor on every boot
cat << EOF > /etc/systemd/system/cpu-governor.service
[Unit]
Description=Set CPU Governor to $GOVERNOR
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do [ -f "\$f" ] && echo $GOVERNOR > "\$f" || true; done; exit 0'

[Install]
WantedBy=multi-user.target
EOF

echo ">> Applying profile instantly and enabling on boot..."
systemctl daemon-reload
systemctl enable --now cpu-governor.service

echo "========================================================"
echo "🎉 SUCCESS: CPU Governor is permanently set to: $GOVERNOR"
echo "========================================================"
