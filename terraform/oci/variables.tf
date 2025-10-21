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

variable "oci_parent_compartment_id" {
  type        = string
  description = "Compartment OCID of the parent compartment"
}

variable "oci_domain_admin_email" {
  type        = string
  description = "Domain administrator's email"
  sensitive   = true
}

variable "oci_instance_shape" {
  type        = string
  default     = "VM.Standard.A1.Flex"
  description = "Instance shape"
}

variable "install_ssh_pub_key" {
  type        = string
  description = "SSH public key to be added as an authorized key to the instances for nix-install"
  sensitive   = true
}

################
## Cloudflare ##
################
variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token with permission to edit DNS record"
  sensitive   = true
}

variable "cloudfare_zone_id" {
  type        = string
  description = "Cloudflare zone id"
  sensitive   = true
}

variable "cloudflare_dns_record" {
  type        = string
  description = "Cloudflare DNS record"
  default     = "k3s.murtazau.xyz"
}
