output "oci_identity_compartment_lab_ocid" {
  value       = oci_identity_compartment.lab.id
  description = "Created Lab compartment's OCID"
}

output "oci_identity_domains_user_gha_terraform_lab_runner_ocid" {
  value       = oci_identity_domains_user.gha_terraform_lab_runner.ocid
  description = "Created Lab domain user's OCID"
}

output "oci_identity_domains_api_key_fingerprint" {
  value       = oci_identity_domains_api_key.api_key.fingerprint
  description = "Added API key's fingerprint"
}
