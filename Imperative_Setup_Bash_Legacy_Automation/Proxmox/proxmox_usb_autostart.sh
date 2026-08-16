#!/bin/bash
# =========================================================================
# proxmox_usb_autostart.sh
# Creates a udev rule to automatically start VM 101 when the USB drive connects
# =========================================================================

echo "========================================================"
echo "🔌 CONFIGURING USB AUTO-START FOR VM 101"
echo "========================================================"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Error: Please run this script with sudo or as root."
  exit 1
fi

RULE_FILE="/etc/udev/rules.d/99-omv-usb.rules"

echo ">> Creating udev rule for ASMedia ASM1153 (174c:1153)..."

# Using systemd-run --no-block ensures the udev process isn't blocked by the qm command
cat << 'EOF' > $RULE_FILE
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="174c", ATTR{idProduct}=="1153", RUN+="/usr/bin/systemd-run --no-block /usr/sbin/qm start 101"
EOF

echo ">> Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

echo "========================================================"
echo "✅ USB AUTO-START CONFIGURED SUCCESSFULLY!"
echo "The next time you press the button on the USB enclosure,"
echo "OpenMediaVault (VM 101) will start automatically."
echo "========================================================"
