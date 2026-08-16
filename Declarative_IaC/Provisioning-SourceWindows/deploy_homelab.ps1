<#
.SYNOPSIS
Deploys the Homelab infrastructure using Terraform and configures it with Ansible.

.DESCRIPTION
This script automates the complete provisioning of the Proxmox VMs via Terraform
and seamlessly hands off the configuration to Ansible (running via WSL) once the VMs are booted.
#>

$ErrorActionPreference = "Stop"

# Resolve the base directory dynamically (one folder up from where this script is located)
$baseDir = Split-Path -Parent $PSScriptRoot
$startTime = Get-Date

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " 🚀 INITIATING HOMELAB DEPLOYMENT" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# 1. Terraform Deployment
Write-Host "`n[1/3] Running Terraform to provision VMs..." -ForegroundColor Yellow
Set-Location -Path "$baseDir\Terraform"

# Initialize Terraform (in case it hasn't been run yet)
terraform init

# Apply the infrastructure
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform failed to apply. Aborting deployment."
    exit 1
}

# 2. Wait for Cloud-Init, VMs to boot, and Disk Watchdog to run
Write-Host "`n[2/3] Waiting for VMs to boot and Disk Watchdog to attach drives (3 minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 180

# 3. Ansible Configuration
Write-Host "`n[3/3] Running Ansible Playbooks via WSL..." -ForegroundColor Yellow
Set-Location -Path "$baseDir\Ansible"

# Ensure WSL translates Windows paths correctly for Ansible by executing inside WSL context
# Configure OpenMediaVault
Write-Host "--> Configuring OpenMediaVault..." -ForegroundColor Green
wsl -e bash -c "ansible-playbook -i hosts.ini omv_setup.yml"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Ansible OMV setup failed. Aborting."
    exit 1
}

# Configure HomeAssistant/Docker/Jellyfin
Write-Host "--> Configuring HomeAssistant (Docker/Jellyfin)..." -ForegroundColor Green
wsl -e bash -c "ansible-playbook -i hosts.ini homeassistant_setup.yml"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Ansible HomeAssistant setup failed."
    exit 1
}

$endTime = Get-Date
$elapsed = $endTime - $startTime

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " ✅ HOMELAB DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host " ⏱ Total Execution Time: $($elapsed.Hours)h $($elapsed.Minutes)m $($elapsed.Seconds)s" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
