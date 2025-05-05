terraform {
  required_version = "~> 1.9"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.35.0"
    }
  }
  cloud {
    organization = "murtaza-u"
    workspaces {
      name = "pre"
    }
  }
}

provider "oci" {
  tenancy_ocid         = var.oci_tenant_id
  auth                 = "ApiKey"
  region               = var.oci_region
  user_ocid            = var.oci_auth_user_id
  fingerprint          = var.oci_auth_key_fingerprint
  private_key_path     = var.oci_auth_private_key_file_path
  private_key_password = var.oci_auth_private_key_password
}
