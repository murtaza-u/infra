resource "flux_bootstrap_git" "lab" {
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
