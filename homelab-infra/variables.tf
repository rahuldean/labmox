variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API URL, e.g. https://192.168.1.2:8006"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API user, e.g. terraform@pve"
}

variable "proxmox_password" {
  type        = string
  sensitive   = true
  description = "Password for the Proxmox API user"
}

variable "proxmox_node" {
  type        = string
  description = "Name of the Proxmox node to deploy on"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Linux bridge interface for container networking"
}

variable "network_gateway" {
  type        = string
  description = "Default gateway IP for containers"
}

variable "lxc_template" {
  type        = string
  description = "Proxmox template ID for Debian 12, e.g. local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "ssh_public_keys" {
  type        = list(string)
  default     = []
  description = "SSH public keys to inject into container root accounts"
}
