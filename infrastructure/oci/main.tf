terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ── OCI Networking ────────────────────────────────────────────────────────────

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "labmox-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "labmox"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "labmox-igw"
  enabled        = true
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "labmox-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# Zero inbound ports — all traffic enters via Cloudflare Tunnel only.
# Egress must remain open so cloudflared can reach Cloudflare's edge.
resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "labmox-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}

resource "oci_core_subnet" "main" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  display_name      = "labmox-subnet"
  cidr_block        = "10.0.1.0/24"
  dns_label         = "main"
  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
}

# ── OCI Compute ───────────────────────────────────────────────────────────────

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

resource "oci_core_instance" "a1" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "labmox-a1"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 3
    memory_in_gbs = 20
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = 150
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main.id
    assign_public_ip = true
    display_name     = "labmox-a1-vnic"
  }

  metadata = {
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tpl", {
      tunnel_id      = cloudflare_zero_trust_tunnel_cloudflared.main.id
      tunnel_secret  = var.tunnel_secret
      account_id     = var.cloudflare_account_id
    }))
  }
}

# ── Cloudflare Tunnel ─────────────────────────────────────────────────────────

resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.cloudflare_account_id
  name       = "labmox-tunnel"
  secret     = var.tunnel_secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id

  config {
    ingress_rule {
      hostname = "aigw.labmox.com"
      service  = "http://localhost:4000"
    }
    ingress_rule {
      hostname = "coolify.labmox.com"
      service  = "http://localhost:8000"
    }
    # Required catch-all
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# ── Cloudflare DNS ────────────────────────────────────────────────────────────

resource "cloudflare_record" "aigw" {
  zone_id = var.cloudflare_zone_id
  name    = "aigw"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  proxied = true
}

resource "cloudflare_record" "coolify" {
  zone_id = var.cloudflare_zone_id
  name    = "coolify"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  proxied = true
}

# ── Cloudflare Access — Service Token (aigw.labmox.com) ──────────────────────

resource "cloudflare_zero_trust_access_application" "api" {
  account_id       = var.cloudflare_account_id
  name             = "aigw"
  domain           = "aigw.labmox.com"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_service_token" "api_client" {
  account_id           = var.cloudflare_account_id
  name                 = "aigw-client"
  min_days_for_renewal = 30
}

resource "cloudflare_zero_trust_access_policy" "api_service_token" {
  account_id     = var.cloudflare_account_id
  application_id = cloudflare_zero_trust_access_application.api.id
  name           = "Service Token"
  precedence     = 1
  decision       = "allow"

  include {
    service_token = [cloudflare_zero_trust_access_service_token.api_client.id]
  }
}

# ── Cloudflare Access — Email Auth (coolify.labmox.com) ──────────────────────

resource "cloudflare_zero_trust_access_application" "coolify" {
  account_id       = var.cloudflare_account_id
  name             = "Coolify"
  domain           = "coolify.labmox.com"
  type             = "self_hosted"
  session_duration = "8h"
}

resource "cloudflare_zero_trust_access_policy" "coolify_email" {
  account_id     = var.cloudflare_account_id
  application_id = cloudflare_zero_trust_access_application.coolify.id
  name           = "Admin Email"
  precedence     = 1
  decision       = "allow"

  include {
    email = [var.admin_email]
  }
}
