#!/bin/bash

# ==============================================================================
# INSTALL DOCKER ENGINE (Official Repository Method)
# ==============================================================================
# Follows official docs: https://docs.docker.com/engine/install/debian/#install-using-the-repository
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

# Run the following command to uninstall all conflicting packages:
# Modified to handle empty outputs safely
apt remove -y $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc 2>/dev/null | cut -f1) || true

# Add Docker's official GPG key:
apt update
apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

#Refreshed its catalog to include the new items from that repository.
apt update

# Install the Docker packages.
# Added -y to auto-accept
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Tells Linux to automatically start Docker every time the computer boots up.
systemctl enable --now docker
# Some systems may have this behavior disabled and will require a manual start:
systemctl start docker
# The Docker service starts automatically after installation. To verify that Docker is running, use:
systemctl status docker --no-pager 

# Check docker and docker compose version:
docker version
docker compose version

# Verify that the installation is successful by running the hello-world image:
docker run --rm hello-world