locals {
  grant_type    = "client_credentials"
  client_id     = oci_identity_domains_app.k3s_idp.name
  client_secret = oci_identity_domains_app.k3s_idp.client_secret
  scope         = "urn:opc:idm:t.security.client"
  access_token  = jsondecode(data.http.oidc_token.response_body).access_token
  kubeconfig = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = "k3s"
      cluster = {
        server                   = var.kubeapi_server_addr
        insecure-skip-tls-verify = true
      }
    }]
    users = [{
      name = "oidc-user"
      user = {
        token = local.access_token
      }
    }]
    contexts = [{
      name = "k3s"
      context = {
        cluster = "k3s"
        user    = "oidc-user"
      }
    }]
    current-context = "k3s"
  })
}

data "http" "oidc_token" {
  url    = "${oci_identity_domains_app.k3s_idp.idcs_endpoint}/oauth2/v1/token"
  method = "POST"
  request_headers = {
    Content-Type = "application/x-www-form-urlencoded"
    Accept       = "application/json"
  }
  request_body = "grant_type=${local.grant_type}&client_id=${local.client_id}&client_secret=${local.client_secret}&scope=${local.scope}"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "non-200 status code returned"
    }
  }
}

resource "github_repository" "infra" {
  name                 = var.github_repository
  description          = "Homelab on a Shoestring"
  visibility           = "public"
  has_issues           = true
  has_discussions      = true
  has_projects         = false
  has_wiki             = false
  vulnerability_alerts = true
  auto_init            = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "null_resource" "wait_for_k3s" {
  provisioner "local-exec" {
    command = <<EOF
    echo "${local.kubeconfig}" > "/tmp/$(mktemp)/kubeconfig.yaml"
    export KUBECONFIG=/tmp/kubeconfig.yaml
    for i in {1..30}; do
      kubectl get nodes --no-headers | awk '{print $2}' | grep -qv "Ready" && sleep 30s || exit 0
    done
    exit 1
    EOF
  }
}

resource "flux_bootstrap_git" "infra" {
  depends_on = [github_repository.infra, null_resource.wait_for_k3s]
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
  path           = "kubernetes/clusters/homelab"
}
