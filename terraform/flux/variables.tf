#########
## OCI ##
#########
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

variable "oci_auth_private_key" {
  type        = string
  description = "Auth private key"
}

variable "oci_auth_private_key_password" {
  type        = string
  description = "Auth private key password"
  sensitive   = true
}

variable "oci_identity_domain_id" {
  type        = string
  description = "ID of the OCI identity domain"
}

variable "oci_identity_domain_app_id" {
  type        = string
  description = "ID of the OCI identity domain app"
}

############
## FluxCD ##
############
variable "github_owner" {
  description = "GitHub owner/organisation name"
  type        = string
  default     = "murtaza-u"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
}
