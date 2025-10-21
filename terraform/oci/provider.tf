terraform {
  required_version = "~> 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  cloud {
    organization = "movingbunker"
    workspaces {
      name = "oci"
    }
  }
}

provider "oci" {
  tenancy_ocid         = var.oci_tenant_id
  auth                 = "ApiKey"
  region               = var.oci_region
  user_ocid            = var.oci_auth_user_id
  fingerprint          = var.oci_auth_key_fingerprint
  private_key          = var.oci_auth_private_key
  private_key_password = var.oci_auth_private_key_password
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "null" {}
