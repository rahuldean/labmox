output "instance_public_ip" {
  description = "Public IP of the A1 instance (not reachable — all access via Cloudflare Tunnel)"
  value       = oci_core_instance.a1.public_ip
}

output "instance_ocid" {
  description = "OCID of the A1 instance"
  value       = oci_core_instance.a1.id
}

output "cloudflare_tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "cf_service_token_client_id" {
  description = "CF-Access-Client-Id header value for programmatic API access"
  value       = cloudflare_zero_trust_access_service_token.api_client.client_id
}

output "cf_service_token_client_secret" {
  description = "CF-Access-Client-Secret header value for programmatic API access"
  value       = cloudflare_zero_trust_access_service_token.api_client.client_secret
  sensitive   = true
}
