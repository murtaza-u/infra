locals {
  hosts = flatten([
    [
      # srv-oci-*
      for i in oci_core_instance.srv_oci_instances : {
        id       = i.id
        hostname = i.display_name
        username = "opc"
        ip       = i.public_ip
      }
    ],
    [
      # srv-onprem-*
      {
        id       = "385efd9b-9b2b-48a7-8f6a-c7011a19d940"
        hostname = "srv-onprem-0"
        username = "nixos"
        ip       = "192.168.29.5"
      }
    ]
  ])
}

module "deploy" {
  for_each                   = { for host in local.hosts : host.hostname => host }
  source                     = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=1.9.0"
  nixos_system_attr          = ".#nixosConfigurations.${each.value.hostname}.config.system.build.toplevel"
  nixos_partitioner_attr     = ".#nixosConfigurations.${each.value.hostname}.config.system.build.diskoScript"
  nixos_generate_config_path = "../hosts/${each.value.hostname}/hardware.nix"
  install_user               = each.value.username
  install_ssh_key            = var.install_ssh_priv_key
  target_host                = each.value.ip
  target_user                = "ops"
  deployment_ssh_key         = var.ops_ssh_priv_key
  extra_files_script         = "${path.module}/hack/ssh-host-key.sh"
  extra_environment          = { SSH_HOST_KEY = var.ops_ssh_priv_key }
  instance_id                = each.value.id # when instance id changes, it will trigger a reinstall
  debug_logging              = true          # useful if something goes wrong
  build_on_remote            = false         # build the closure on the remote machine instead of locally
}
