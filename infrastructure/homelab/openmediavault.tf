locals {
  openmediavault = {
    vm_id        = 103
    ip_address   = "192.168.1.13/24"
    cpu_cores    = 2
    memory_mb    = 2048
    disk_size_gb = 16
    tags         = ["homelab", "storage"]
  }
}

module "openmediavault" {
  source = "./modules/lxc"

  hostname     = "openmediavault"
  vm_id        = local.openmediavault.vm_id
  ip_address   = local.openmediavault.ip_address
  cpu_cores    = local.openmediavault.cpu_cores
  memory_mb    = local.openmediavault.memory_mb
  disk_size_gb = local.openmediavault.disk_size_gb
  tags         = local.openmediavault.tags

  proxmox_node    = var.proxmox_node
  network_bridge  = var.network_bridge
  network_gateway = var.network_gateway
  lxc_template    = var.lxc_template
  ssh_public_keys = var.ssh_public_keys
}
