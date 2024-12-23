terraform {
  cloud {
    organization = "murtaza-u"
    workspaces {
      name = "homelab-flux"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.4.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.4.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "flux" {
  kubernetes = {
    config_paths = [
      "~/.kube/config",
      "kubeconfig"
    ]
  }
  git = {
    url = "https://github.com/${var.github_owner}/${var.github_repository}"
    http = {
      username = "git"
      password = var.github_token
    }
    author_email = "bot@fluxcd.io"
    author_name  = "Flux Bot"
    branch       = "main"
  }
}

resource "github_repository" "this" {
  name                 = var.github_repository
  description          = "Homelab on a Shoestring"
  visibility           = "public"
  has_issues           = true
  has_discussions      = true
  has_projects         = false
  has_wiki             = false
  vulnerability_alerts = true
  auto_init            = true
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository.this]
  components_extra = [
    "image-reflector-controller",
    "image-automation-controller"
  ]
  # flux manifests will be extracted from the provider binary instead of being
  # downloaded from GitHub.
  embedded_manifests = true
  # interval at which to reconcile from bootstrap repository.
  interval = "1m0s"
  # keep the namespace after uninstalling Flux components.
  keep_namespace = false
  namespace      = "flux-system"
  path           = "clusters/homelab"
}
