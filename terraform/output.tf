output "oci_instances_information" {
  value       = [for i in oci_core_instance.srv_oci_instances : i.public_ip]
  description = "Created instances' public IP"
}

output "oci_icds_endpoint" {
  value       = oci_identity_domain.lab.url
  description = "ICDS endpoint"
}
