#!/bin/bash
set -e

echo "============================================================"
echo "    Installing Telegraf for InfluxDB (Dashboard 20165)"
echo "============================================================"

# Add InfluxData repository
rm -f /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg
wget -qO- https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor --yes | tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list

# Update and install
apt-get update
apt-get install -y telegraf lm-sensors

# Backup original config
mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.bak || true

# Write the extensive configuration required by Dashboard 20165
cat << 'EOF' > /etc/telegraf/telegraf.conf
[agent]
  interval = "60s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "2s"
  collection_offset = "0s"
  flush_interval = "60s"
  flush_jitter = "2s"
  precision = "0s"
  hostname = ""
  omit_hostname = false

###############################################################################
# OUTPUT PLUGINS
###############################################################################
[[outputs.influxdb_v2]]
  urls = ["http://192.168.X.X:8086"]
  token = "<YOUR_INFLUXDB_TOKEN>"
  organization = "pve1"
  bucket = "proxmox"

###############################################################################
# INPUT PLUGINS
###############################################################################
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
  use_sudo = false
[[inputs.swap]]
[[inputs.system]]
[[inputs.sensors]]

[[inputs.dns_query]]
  servers = ["8.8.8.8", "1.1.1.1"]

[[inputs.http_response]]
  urls = ["https://google.com", "https://yahoo.com"]
  follow_redirects = true

[[inputs.internal]]
[[inputs.interrupts]]
[[inputs.kernel_vmstat]]
[[inputs.linux_sysctl_fs]]
[[inputs.mdstat]]

[[inputs.net]]
[[inputs.netstat]]
[[inputs.nstat]]
  dump_zeros = true

[[inputs.ping]]
  urls = ["google.com", "yahoo.com", "1.1.1.1"]
  ping_interval = 5.0

EOF

# Restart Telegraf to apply the new configuration
systemctl restart telegraf

echo "Telegraf installation and configuration complete!"
