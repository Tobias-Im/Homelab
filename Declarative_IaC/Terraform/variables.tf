variable "proxmox_api_url" {
  type        = string
  description = "The Proxmox API URL (e.g. https://192.168.1.100:8006/api2/json)"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "The API Token ID (e.g. root@pam!terraform)"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "The secret UUID for the API token"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The Proxmox Node name (e.g. pve1)"
  default     = "pve1"
}

variable "vm_storage_pool" {
  type        = string
  description = "The storage pool for VM disks"
  default     = "local"
}

variable "vm_password_omv" {
  type        = string
  description = "The password for the OMV VM user (used for sudo and login)"
  sensitive   = true
}

variable "vm_password_homelab" {
  type        = string
  description = "The password for the Homelab VM user (used for sudo and login)"
  sensitive   = true
}

variable "vm_ssh_public_key" {
  type        = string
  description = "The public SSH key to inject into the VM for passwordless login"
}

variable "vm_password_monitoring" {
  type        = string
  description = "The password for the Monitoring VM user (used for sudo and login)"
  sensitive   = true
}
