output "container_id" {
  description = "Proxmox VMID assigned to this container"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "ip_address" {
  description = "Container IP address (bare, without CIDR prefix)"
  # Strip the CIDR suffix to get a bare IP for use in templates and outputs
  value = split("/", var.ip_address)[0]
}

output "hostname" {
  description = "Container hostname"
  value       = var.hostname
}
