terraform {
  required_version = "~> 1.12"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.2.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.5.1"
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

provider "http" {}

provider "flux" {
  kubernetes = {
    host     = var.kubeapi_server_addr
    insecure = true
    token    = local.access_token
  }
  git = {
    url = "https://github.com/${var.github_owner}/${var.github_repository}"
    http = {
      username = "git"
      password = var.github_token
    }
    author_email = "bot@fluxcd.io"
    author_name  = "Flux Bot"
    branch       = "redefine"
  }
}
