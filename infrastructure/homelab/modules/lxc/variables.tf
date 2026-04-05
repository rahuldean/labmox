variable "hostname" {
  type        = string
  description = "Container hostname"
}

variable "vm_id" {
  type        = number
  default     = null
  nullable    = true
  description = "Proxmox VMID. Leave null to auto-assign."
}

variable "ip_address" {
  type        = string
  description = "Static IP in CIDR notation, e.g. 192.168.1.10/24"
}

variable "cpu_cores" {
  type        = number
  description = "Number of CPU cores"

  validation {
    condition     = var.cpu_cores > 0
    error_message = "cpu_cores must be greater than 0."
  }
}

variable "memory_mb" {
  type        = number
  description = "Dedicated memory in MB"

  validation {
    condition     = var.memory_mb >= 64
    error_message = "memory_mb must be at least 64 MB."
  }
}

variable "disk_size_gb" {
  type        = number
  description = "Root disk size in GB"

  validation {
    condition     = var.disk_size_gb > 0
    error_message = "disk_size_gb must be greater than 0."
  }
}

variable "disk_storage" {
  type        = string
  description = "Proxmox storage pool for the disk"
  default     = "local-lvm"
}

variable "tags" {
  type        = list(string)
  description = "List of tags to apply to the container"
  default     = []
}

variable "unprivileged" {
  type        = bool
  description = "Run the container in unprivileged mode (recommended). Set to false for Docker-in-LXC"
  default     = true
}

variable "features_nesting" {
  type        = bool
  default     = false
  description = "Enable LXC nesting - required when running Docker inside LXC"
}

variable "start_on_boot" {
  type        = bool
  description = "Start the container automatically when the Proxmox node boots"
  default     = true
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys to inject into the container's root account"
  default     = []
}

variable "proxmox_node" {
  type        = string
  description = "Name of the Proxmox node to create the container on"
}

variable "network_bridge" {
  type        = string
  description = "Linux bridge interface for the container's network interface"
}

variable "network_gateway" {
  type        = string
  description = "Default gateway IP for the container"
}

variable "lxc_template" {
  type        = string
  description = "Proxmox template file ID to use for the container OS"
}
