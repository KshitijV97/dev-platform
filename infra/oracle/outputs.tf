output "instance_id" {
  description = "OCID of the primary instance."
  value       = oci_core_instance.primary.id
}

output "public_ip" {
  description = "Public IPv4 address of the primary instance."
  value       = oci_core_instance.primary.public_ip
}

output "region" {
  description = "Region the instance was created in."
  value       = var.region
}
