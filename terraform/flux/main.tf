locals {
  kubeconfig = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = "k3s"
      cluster = {
        server                   = "https://k3s.murtazau.xyz:6443"
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

resource "null_resource" "wait_for_k3s" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      KUBECONFIG_RAW = local.kubeconfig
    }
    command = <<EOF
      set -e
      export KUBECONFIG="$(mktemp)"
      echo "$KUBECONFIG_RAW" > "$KUBECONFIG"
      for _ in {1..30}; do
        ready_count="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready" {count++} END {print count+0}')"
        if [[ "$ready_count" -ge 1 ]]; then
            echo "cluster is ready"
          exit 0
        fi
        echo "cluster not ready...waiting for 30s before retrying"
        sleep 30s
      done
      echo "cluster not ready...giving up"
      exit 1
    EOF
  }
}

resource "flux_bootstrap_git" "homelab" {
  depends_on = [null_resource.wait_for_k3s]
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
