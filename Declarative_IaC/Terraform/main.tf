# ==============================================================================
# DEBIAN (JELLYFIN) VM
# ==============================================================================
resource "proxmox_virtual_environment_vm" "homelab" {
  name      = "Homelab"
  node_name = var.proxmox_node
  vm_id     = 102

  # Auto-Start: Homelab starts second (after OMV)
  on_boot = true
  startup {
    order    = 2
    up_delay = 60 # Give OMV 60 seconds to start its NFS server
  }

  # Core Hardware (Matching your config)
  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 12288
  }

  agent {
    enabled = true
  }

  # Clone from Debian 13 Cloud-Init Template
  clone {
    vm_id = 9000
  }

  # Graphics
  vga {
    type = "std"
  }

  # Boot Drive Configuration (VirtIO SCSI Single + SSD + Discard)
  disk {
    datastore_id = "local"
    file_format  = "qcow2"
    interface    = "scsi0"
    size         = 100
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  # UEFI Boot Disk
  efi_disk {
    datastore_id      = "local"
    file_format       = "qcow2"
    type              = "4m"
    pre_enrolled_keys = true
  }

  # Network
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    firewall    = false
    mac_address = "52:54:00:A1:B2:C3"
  }

  # Attach the AMD GPU (Barcelo rev c1) for Hardware Transcoding
  hostpci {
    device  = "hostpci0"
    mapping = "amdgpu"
    pcie    = true
    rombar  = false
  }

  # Enable Serial Console (Required for xterm.js)
  serial_device {}

  # Cloud-Init Initialization
  initialization {
    datastore_id = var.vm_storage_pool
    ip_config {
      ipv4 {
        address = "192.168.X.X/24"
        gateway = "192.168.X.X"
      }
    }
    user_account {
      username = "Saturday"
      password = var.vm_password_homelab
      keys     = [var.vm_ssh_public_key]
    }
  }
}

# ==============================================================================
# OPENMEDIAVAULT VM
# ==============================================================================
resource "proxmox_virtual_environment_vm" "openmediavault" {
  name      = "OpenMediaVault"
  node_name = var.proxmox_node
  vm_id     = 101

  # Auto-Start: OMV starts first
  on_boot = true
  startup {
    order = 1
  }

  # Core Hardware (Matching your config)
  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  # Clone from Debian 13 Cloud-Init Template
  clone {
    vm_id = 9000
  }

  # Graphics
  vga {
    type = "std"
  }

  # Boot Drive Configuration (VirtIO SCSI Single + SSD + Discard)
  disk {
    datastore_id = "local"
    file_format  = "qcow2"
    interface    = "scsi0"
    size         = 32
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  # UEFI Boot Disk
  efi_disk {
    datastore_id      = "local"
    file_format       = "qcow2"
    type              = "4m"
    pre_enrolled_keys = true
  }

  # Network
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    firewall    = false
    mac_address = "52:54:00:D4:E5:F6"
  }



  # Enable Serial Console (Required for your omv_enable_serial_console.sh script)
  serial_device {}

  # Cloud-Init Initialization
  initialization {
    datastore_id = var.vm_storage_pool
    ip_config {
      ipv4 {
        address = "192.168.X.X/24"
        gateway = "192.168.X.X"
      }
    }
    user_account {
      username = "Saturday"
      password = var.vm_password_omv
      keys     = [var.vm_ssh_public_key]
    }
  }

  # Prevent Terraform from trying to delete disks attached manually via the null_resource
  lifecycle {
    ignore_changes = [
      disk,
    ]
  }
}

# ==============================================================================
# MONITORING VM
# ==============================================================================
resource "proxmox_virtual_environment_vm" "monitoring" {
  name      = "Monitoring"
  node_name = var.proxmox_node
  vm_id     = 103

  # Auto-Start: Starts after Homelab
  on_boot = true
  startup {
    order    = 3
    up_delay = 30
  }

  # Core Hardware
  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 12288
  }

  agent {
    enabled = true
  }

  # Clone from Debian 13 Cloud-Init Template
  clone {
    vm_id = 9000
  }

  # Graphics
  vga {
    type = "std"
  }

  # Boot Drive Configuration (VirtIO SCSI Single + SSD + Discard)
  disk {
    datastore_id = "local"
    file_format  = "qcow2"
    interface    = "scsi0"
    size         = 100
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  # UEFI Boot Disk
  efi_disk {
    datastore_id      = "local"
    file_format       = "qcow2"
    type              = "4m"
    pre_enrolled_keys = true
  }

  # Network
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    firewall    = false
    mac_address = "52:54:00:1A:2B:3C"
  }

  # Enable Serial Console
  serial_device {}

  # Cloud-Init Initialization
  initialization {
    datastore_id = var.vm_storage_pool
    ip_config {
      ipv4 {
        address = "192.168.X.X/24"
        gateway = "192.168.X.X"
      }
    }
    user_account {
      username = "Saturday"
      password = var.vm_password_monitoring
      keys     = [var.vm_ssh_public_key]
    }
  }
}
