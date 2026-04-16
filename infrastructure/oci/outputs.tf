output "instance_public_ip" {
  description = "Public IP of the A1 instance"
  value       = oci_core_instance.a1.public_ip
}

output "instance_ocid" {
  description = "OCID of the A1 instance"
  value       = oci_core_instance.a1.id
}
