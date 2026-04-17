# ── OCI ──────────────────────────────────────────────────────────────────────

variable "tenancy_ocid" {
  type        = string
  description = "OCID of your OCI tenancy"
}

variable "user_ocid" {
  type        = string
  description = "OCID of the OCI user running Terraform"
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the API signing key"
}

variable "private_key_path" {
  type        = string
  description = "Path to the PEM private key for OCI API authentication"
}

variable "region" {
  type        = string
  description = "OCI region, e.g. us-ashburn-1"
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to deploy into (use root tenancy OCID for free tier)"
}

variable "image_ocid" {
  type        = string
  description = "OCID of the ARM/aarch64 Ubuntu 22.04 image — find at https://docs.oracle.com/en-us/iaas/images/"
}

# ── Cloudflare ────────────────────────────────────────────────────────────────

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token with Zero Trust + DNS Edit permissions"
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID (found in dashboard URL or account settings)"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for labmox.com"
}

variable "tunnel_secret" {
  type        = string
  sensitive   = true
  description = "Base64-encoded 32-byte secret for the Cloudflare tunnel. Generate with: openssl rand -base64 32"
}

variable "admin_email" {
  type        = string
  description = "Email address allowed to access coolify.labmox.com via Cloudflare Access"
}
