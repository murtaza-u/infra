variable "oci_region" {
  type        = string
  default     = "ap-mumbai-1"
  description = "OCI region to deploy resources to"
}

variable "oci_tenant_id" {
  type        = string
  description = "Tenant OCID"
}

variable "oci_auth_user_id" {
  type        = string
  description = "Auth user OCID"
}

variable "oci_auth_key_fingerprint" {
  type        = string
  description = "Auth public key's fingerprint"
}

variable "oci_auth_private_key_file_path" {
  type        = string
  description = "Auth private key file path"
}

variable "oci_parent_compartment_id" {
  type        = string
  description = "Compartment OCID of the parent compartment"
}

variable "oci_domain_admin_email" {
  type        = string
  description = "Domain administrator's email"
  sensitive   = true
}

variable "oci_gha_terraform_runner_api_pubkey" {
  type        = string
  description = "Public key that needs to be added"
  sensitive   = true
}
