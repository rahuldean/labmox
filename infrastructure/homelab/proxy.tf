locals {
  proxy = {
    vm_id        = 100
    ip_address   = "192.168.1.10/24"
    cpu_cores    = 1
    memory_mb    = 512
    disk_size_gb = 8
    tags         = ["homelab", "proxy"]
  }

  # Ports for services running in the docker LXC
  immich_port    = 2283
  paperless_port = 8000
  backrest_port  = 9898
  vscode_port    = 8080
}

module "proxy" {
  source = "./modules/lxc"

  hostname     = "proxy"
  vm_id        = local.proxy.vm_id
  ip_address   = local.proxy.ip_address
  cpu_cores    = local.proxy.cpu_cores
  memory_mb    = local.proxy.memory_mb
  disk_size_gb = local.proxy.disk_size_gb
  tags         = local.proxy.tags

  proxmox_node    = var.proxmox_node
  network_bridge  = var.network_bridge
  network_gateway = var.network_gateway
  lxc_template    = var.lxc_template
  ssh_public_keys = var.ssh_public_keys
}

resource "local_file" "caddyfile" {
  content = templatefile("${path.root}/templates/Caddyfile.tpl", {
    docker_ip      = module.docker.ip_address
    immich_port    = local.immich_port
    paperless_port = local.paperless_port
    backrest_port  = local.backrest_port
    vscode_port    = local.vscode_port
  })
  filename = "${path.root}/rendered/Caddyfile"
}
