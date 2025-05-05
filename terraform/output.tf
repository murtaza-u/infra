output "oci_instances_information" {
  value       = [for i in oci_core_instance.srv_oci_instances : i.public_ip]
  description = "Created instances' public IP"
}
