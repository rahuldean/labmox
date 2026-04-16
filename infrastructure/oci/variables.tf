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
  description = "OCID of the ARM/aarch64 Ubuntu 22.04 image - find at https://docs.oracle.com/en-us/iaas/images/"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key contents to inject into the instance"
}
