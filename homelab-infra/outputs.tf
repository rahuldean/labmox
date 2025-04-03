output "proxy_ip" {
  value       = module.proxy.ip_address
  description = "IP address of the Caddy proxy container"
}

output "proxy_id" {
  value       = module.proxy.container_id
  description = "Proxmox VMID of the Caddy proxy container"
}

output "pihole_ip" {
  value       = module.pihole.ip_address
  description = "IP address of the Pi-hole container"
}

output "pihole_id" {
  value       = module.pihole.container_id
  description = "Proxmox VMID of the Pi-hole container"
}

output "docker_ip" {
  value       = module.docker.ip_address
  description = "IP address of the Docker host container"
}

output "docker_id" {
  value       = module.docker.container_id
  description = "Proxmox VMID of the Docker host container"
}

output "openmediavault_ip" {
  value       = module.openmediavault.ip_address
  description = "IP address of the OpenMediaVault container"
}

output "openmediavault_id" {
  value       = module.openmediavault.container_id
  description = "Proxmox VMID of the OpenMediaVault container"
}

output "caddyfile_path" {
  value       = "${path.root}/rendered/Caddyfile"
  description = "Local path to the rendered Caddyfile — scp this to /etc/caddy/Caddyfile on the proxy LXC"
}
