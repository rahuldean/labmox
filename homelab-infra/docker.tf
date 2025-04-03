# This container runs Docker (Immich, Paperless-NGX, Backrest-Sync, VS Code Server).
# It needs privileged mode and LXC nesting to run Docker inside an LXC.

locals {
  docker = {
    vm_id        = 102
    ip_address   = "192.168.1.12/24"
    cpu_cores    = 4
    memory_mb    = 8192
    disk_size_gb = 64
    tags         = ["homelab", "docker"]
  }
}

module "docker" {
  source = "./modules/lxc"

  hostname         = "docker"
  vm_id            = local.docker.vm_id
  ip_address       = local.docker.ip_address
  cpu_cores        = local.docker.cpu_cores
  memory_mb        = local.docker.memory_mb
  disk_size_gb     = local.docker.disk_size_gb
  tags             = local.docker.tags
  unprivileged     = false
  features_nesting = true

  proxmox_node    = var.proxmox_node
  network_bridge  = var.network_bridge
  network_gateway = var.network_gateway
  lxc_template    = var.lxc_template
  ssh_public_keys = var.ssh_public_keys
}
