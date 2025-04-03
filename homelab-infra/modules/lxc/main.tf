terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.69"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  tags          = var.tags
  start_on_boot = var.start_on_boot
  unprivileged  = var.unprivileged

  features {
    nesting = var.features_nesting
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.network_gateway
      }
    }

    user_account {
      keys = var.ssh_public_keys
    }
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.disk_storage
    size         = var.disk_size_gb
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }
}
