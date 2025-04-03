locals {
  pihole = {
    vm_id        = 101
    ip_address   = "192.168.1.11/24"
    cpu_cores    = 1
    memory_mb    = 512
    disk_size_gb = 8
    tags         = ["homelab", "dns"]
  }
}

module "pihole" {
  source = "./modules/lxc"

  hostname     = "pihole"
  vm_id        = local.pihole.vm_id
  ip_address   = local.pihole.ip_address
  cpu_cores    = local.pihole.cpu_cores
  memory_mb    = local.pihole.memory_mb
  disk_size_gb = local.pihole.disk_size_gb
  tags         = local.pihole.tags

  proxmox_node    = var.proxmox_node
  network_bridge  = var.network_bridge
  network_gateway = var.network_gateway
  lxc_template    = var.lxc_template
  ssh_public_keys = var.ssh_public_keys
}
