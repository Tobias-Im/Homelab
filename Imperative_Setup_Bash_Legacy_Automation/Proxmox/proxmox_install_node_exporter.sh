#!/bin/bash

# ==============================================================================
# PROXMOX INSTALL NODE EXPORTER
# Installs prometheus-node-exporter to natively expose hardware metrics (CPU, 
# RAM, Disk I/O) to the central Prometheus monitoring stack.
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

echo "========================================================"
echo "📊 INSTALLING PROMETHEUS NODE EXPORTER"
echo "========================================================"

echo ">> Updating apt cache..."
apt-get update -qq

echo ">> Installing prometheus-node-exporter..."
apt-get install -y prometheus-node-exporter -qq

echo ">> Ensuring the service is enabled and started..."
systemctl enable --now prometheus-node-exporter

echo "✅ Node Exporter successfully installed and running on port 9100!"
