# Infrastructure Documentation

This document provides a comprehensive overview of the homelab and CyberLab environment, detailing the architecture, provisioning methodologies, active services, custom automation scripts, and network exposure strategies.

---

## Hardware Specifications

The entire infrastructure runs on a single, highly efficient micro-server node with external attached mass storage:

*   **Compute Node:** GMKtec NucBox M5 Plus Mini PC
*   **Hypervisor:** Proxmox Virtual Environment (PVE) Bare-Metal
*   **CPU:** AMD Ryzen™ 7 5825U (8 Cores / 16 Threads)
*   **Memory:** 64GB (2 x 32GB ADATA Premier DDR4, 3200MHz, CL22)
*   **Primary Storage (OS/VMs):** 1TB Kingston NV2 PCIe 4.0 NVMe M.2 SSD
*   **Mass Storage (Media/Data):** 8TB Seagate Exos 7E10 Enterprise SATA 3.5" HDD, housed within UGREEN USB 3.0 external enclosure.
*   **Backup Storage:** 2TB WD Elements Portable 2.5" USB 3.0 External HDD.

---

## 1. Homelab Infrastructure

The homelab is designed to be highly resilient, automated, and easily reproducible. The deployment process starts with imperative bash scripts for mandatory bare-metal prerequisites, followed by modern Infrastructure as Code (IaC) for dynamic VM provisioning.

### 1.1 Mandatory Prerequisites
The foundation of the infrastructure relies on a robust suite of autonomous bash scripts located in `Imperative_Setup_Bash_Legacy_Automation`. These must be executed first:
*   **Proxmox Host Setup (`\Imperative_Setup_Bash_Legacy_Automation\Proxmox`):** Contains the `main_proxmox_fresh_install.sh` script, which executes critical hardware prerequisites mandatory for the lab to function (e.g., IOMMU setup, AMD GPU isolation, PCI Datacenter mapping, Realtek network drivers, automated USB disk watchdogs, Cloud-Init template generation).

### 1.2 Imperative Provisioning (Imperative_Setup_Bash_Legacy_Automation)
*   **CyberLab VMs (`\Imperative_Setup_Bash_Legacy_Automation\Proxmox\CyberLab`):** Contains the scripts responsible for automatically creating the dedicated cyber security virtual machines (Kali, REMnux, and the zero-touch FLARE-VM template).
*   **Homelab VMs (`\Imperative_Setup_Bash_Legacy_Automation\Proxmox\Homelab`):** Contains scripts that automate the deployment of the core Homelab VMs (**OpenMediaVault**, **Homelab App Server**, and **Monitoring Server**) on Proxmox. These scripts orchestrate template cloning, hardware provisioning (Q35 machine types, OVMF BIOS, SSD emulation), network bridge configuration, and Cloud-Init initialization.
*   **Debian Automations (`\Imperative_Setup_Bash_Legacy_Automation\Debian`):** Contains internal OS configuration scripts designed to bootstrap a fresh Debian VM. They handle Proxmox integration (QEMU Guest Agent, serial console), system tuning (swappiness), Docker installation, security hardening (fail2ban, unattended upgrades, SSH restrictions), and AMD GPU driver installation for hardware acceleration.

### 1.3 Dynamic Provisioning (Declarative_IaC)
Once the Proxmox bare-metal prerequisites are met, the modern deployment workflow takes over, fully automated using **Terraform** and **Ansible**.
*   **Provisioning (Terraform):** Defines the Proxmox Virtual Machines, their hardware specifications, and networking dynamically.
*   **Configuration (Ansible):** Once Terraform spins up the VMs, Ansible automatically connects via SSH to configure the OS using distinct playbooks:
    *   **`omv_setup.yml`**: 
        *   System optimization (Swappiness for SSDs, GRUB Serial Console).
        *   OpenMediaVault Core and OMV-Extras plugin installation.
        *   NFS shared folder directory configuration.
        *   Automated deployment of a monolithic "Golden Configuration" file (`omv_config.xml`).
    *   **`homeassistant_setup.yml`**:
        *   System hardening (SSH restrictions, Fail2Ban, Unattended Upgrades).
        *   Hardware optimization (AMD GPU drivers for hardware transcoding, swappiness adjustments).
        *   NFS mounts (mounting OpenMediaVault storage).
        *   Docker CE installation.
        *   Upload of custom saved administration scripts and deployment of static cron jobs.
        *   Automated payload extraction and restoration of the Docker homelab environment from pre-packaged `.tar.gz` backups.
    *   **`monitoring_setup.yml`**:
        *   System hardening (SSH restrictions, Fail2Ban, Unattended Upgrades).
        *   System optimization (Elasticsearch `vm.max_map_count` for Wazuh, Swappiness).
        *   Upload of custom saved administration scripts and deployment of static cron jobs.
        *   Automated payload extraction and restoration of the observability and Wazuh SIEM stack from `.tar.gz` backups.

---

## 2. CyberLab Infrastructure (Imperative_Setup_Bash_Legacy_Automation\Proxmox\CyberLab)

The environment features a dedicated, automated deployment pipeline for spinning up disposable, ephemeral malware analysis and offensive security labs on Proxmox.

*   **Kali Linux:** Fully automated deployment of the official offensive security OS for penetration testing and red teaming.
*   **REMnux:** Automated deployment of the Linux toolkit for reverse engineering and analyzing malicious software.
*   **FLARE-VM (Golden Template):** A complex, Zero-Touch automated pipeline that installs a base Windows 10 Evaluation ISO, injects an unattended answer file, bypasses Windows Defender Tamper Protection, and executes the Mandiant FLARE-VM installation. It uses a custom process monitor to wait for the 3-hour installation to finish before automatically sealing the VM into a read-only **Proxmox Template**. This allows instant deployment of disposable "Linked Clones" for detonating destructive malware.

---

## 3. Services Architecture (Docker Compose)

The environment runs two distinct Docker engines to separate production applications from observability and security monitoring. 

### 3.1 Homelab VM (\files\Homelab\docker-compose.yml)
The primary application server runs a vast suite of Docker containers:

**Media & Entertainment:**
*   **Jellyfin:** Primary media server, accelerated by AMD GPU hardware transcoding.
*   **Navidrome:** Personal music streaming server.

**The *Arr Stack:**
*   **Radarr / Sonarr / Lidarr:** Automated movie, TV show, and music management.
*   **Prowlarr / Bazarr:** Indexer proxy and automated subtitle management.
*   **Jellyseerr:** Media request management and discovery interface.
*   **qBittorrent:** Torrent client routed entirely through a custom Gluetun VPN tunnel.
*   **FlareSolverr:** Proxy server to bypass Cloudflare protection for indexers.

**Networking & Security:**
*   **Nginx Proxy Manager:** Handles incoming web traffic and automatic SSL certificates.
*   **CrowdSec (WAF):** Intrusion detection system and Web Application Firewall analyzing Nginx logs in real-time.
*   **Wireguard (wg-easy):** Self-hosted VPN for secure remote access into the homelab.
*   **Gluetun:** Swiss-army-knife VPN client routing traffic for the *Arr stack.
*   **Cloudflare-DDNS:** Dynamically updates DNS records.

**Management & Diagnostics:**
*   **Portainer:** Web-based Docker container management.
*   **Watchtower:** Automated, rolling updates for Docker images.
*   **Dozzle & Dockpeek:** Real-time log viewing and container management interfaces.
*   **Heimdall:** Application dashboard/launchpad.
*   **cAdvisor & Node Exporter:** Exposes hardware and container metrics to the Monitoring VM.
*   **MySpeed / OpenSpeedTest:** Automated network speed tracking.

### 3.2 Monitoring VM (\files\Monitoring\docker-compose*.yml)
The dedicated observability server monitors the health and security of the entire infrastructure.

**Observability Stack:**
*   **Prometheus:** Time-series database for collecting cluster-wide metrics.
*   **Grafana:** Visualization dashboard for hardware, network, and Docker monitoring.
*   **InfluxDB:** High-performance datastore for Proxmox cluster metrics.
*   **Uptime Kuma:** Proactive health monitoring and alerting for all VMs and containers.
*   **PVE-Exporter:** Exports native Proxmox VE API metrics to Prometheus.

**Security & SIEM:**
*   **Wazuh (SIEM):** Endpoint security and log analysis.
*   **Greenbone (OpenVAS):** Active vulnerability scanner *(Work in progress for future deployment)*.

---

## 4. Network & Cloudflare Architecture

The infrastructure employs a highly secure, split-routing network architecture. It uses dynamic DNS combined with Cloudflare proxying for ingress, while forcing high-risk outbound traffic through an encrypted VPN tunnel.

### 4.1 Ingress (Incoming Web Traffic)
*   **Cloudflare DNS & Proxy:** All subdomains are proxied through Cloudflare's edge network for DDoS protection, caching, and IP masking. 
*   **Dynamic DNS (`cloudflare-ddns`):** A dedicated container continuously monitors the physical router's WAN IP and uses the Cloudflare API to automatically update the DNS `A` records if the ISP changes the IP address.
*   **Nginx Proxy Manager (`npmplus`):** The physical router port-forwards ports `80` and `443` directly to the Homelab VM. Nginx Proxy Manager intercepts this traffic, handles automatic SSL certificate, and securely routes the requests to the correct internal Docker containers.
*   **CrowdSec (WAF):** An active intrusion detection system that mounts the Nginx logs in read-only mode. It analyzes incoming web requests in real-time, detecting vulnerability scanners and brute-force attempts. Malicious IPs are immediately blocked at the Nginx gateway via the CrowdSec Bouncer.

### 4.2 Egress (Outgoing Privacy Traffic)
*   **Gluetun VPN Tunnel:** A dedicated container establishes a strict, encrypted Wireguard tunnel to a commercial VPN provider. 
*   **Container Network Binding:** High-risk applications (e.g., `qBittorrent`, `Prowlarr`, `Radarr`, `Sonarr`) are completely stripped of their default network access. Using Docker's `network_mode: "service:gluetun"`, these containers are physically bound to the Gluetun network stack. All of their outbound internet traffic is forced through the encrypted VPN tunnel, completely preventing ISP snooping or home IP address leakage.

---

## 5. Custom Scripts & Automations

The infrastructure is maintained by a suite of custom shell scripts designed to solve specific homelab pain points:

*   **Docker Lifecycle & Backups (`\files\Homelab\Scripts\BackUp`):** A suite of disaster recovery scripts that automate the entire backup and restore pipeline. They handle gracefully stopping Docker containers, compressing all configurations and volumes into a single archive, pruning old local backups to save space, and securely syncing the payloads to Google Drive using `rclone`.
*   **Jellyfin Media Processing (`\files\Homelab\Scripts\Jellyfin`):** Custom `mkvmerge` batch scripts that automatically strip excess embedded subtitle streams from downloaded media. This is a targeted workaround for an older Samsung TizenOS TV client that produces severe visual artifacts when parsing MKV files with too many subtitle tracks. The scripts strip everything except the Romanian (`rum`) track to ensure smooth playback.

---

## 6. Backup & Disaster Recovery

The infrastructure employs a comprehensive, multi-tiered disaster recovery plan ensuring zero data loss and rapid recovery.

*   **Bare-Metal Level (Proxmox Backup Server):** PBS is integrated directly into the hypervisor, performing automated, incremental, and deduplicated snapshots of the entire Virtual Machine ecosystem.
*   **Application Level (Docker Payloads):** Custom bash scripts (`homelab_backup.sh`) gracefully stop all Docker containers, compress all persistent `/config` volumes and databases into timestamped `.tar.gz` payloads, and immediately restart the services to minimize downtime.
*   **Off-Site Cloud Sync (Rclone):** A dedicated cron script (`homelab_cloud_upload.sh`) leverages `rclone` to securely sync the `.tar.gz` payloads to an off-site cloud storage provider.
*   **Zero-Touch Restoration:** In the event of a catastrophic failure, the Ansible IaC pipelines (`homeassistant_setup.yml` and `monitoring_setup.yml`) automatically extract these `.tar.gz` payloads during provisioning, spinning up the Docker engines to seamlessly restore the environment exactly as it was.
---

## 7. Windows Source Provisioning

For users deploying from a Windows workstation, this repository includes native PowerShell helper scripts to automate the initial configuration and deployment processes across both the declarative and legacy infrastructure models:

*   **Declarative Provisioning (\Declarative_IaC\Provisioning-SourceWindows):** Contains deploy_homelab.ps1, a streamlined utility to rapidly execute Terraform and Ansible pipelines directly from a Windows host.
*   **Imperative Provisioning (\Imperative_Setup_Bash_Legacy_Automation\Provisioning-SourceWindows):** Contains deployment wrappers (deploy_scripts_windows_debian.ps1, deploy_scripts_windows_proxmox.ps1, deploy_scripts_windows_omv.ps1) that automatically connect via SSH, create the necessary directories on the remote Linux servers, and securely copy over the legacy Bash automation scripts for local execution.

---

## 8. Security & Privacy Notice

Please note that **all sensitive information has been systematically scrubbed and anonymized** before publishing this repository. 
If you plan to fork or deploy this infrastructure, you **must** update the placeholders with your own data:
*   **IP Addresses & MACs:** Internal IP addresses have been replaced with 192.168.X.X and hardware MAC addresses randomized.
*   **Credentials & Paths:** Usernames, absolute paths, and system passwords have been replaced with safe placeholders (e.g., Saturday, Sunday, /path/).
*   **API Tokens & Secrets:** All Proxmox, Cloudflare, InfluxDB, and other API secrets have been replaced with explicit placeholder strings (e.g., <YOUR_API_TOKEN>).
*   **Excluded Files:** For security and privacy reasons, the actual Homelab backups, Monitoring backups, and the OpenMediaVault `config.xml` have been intentionally excluded from this repository on \files.
