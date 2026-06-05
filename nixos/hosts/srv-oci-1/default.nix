{ lib, config, extraArgs, inputs, ... }:
let
  infra = lib.importJSON (builtins.getEnv "TF_OUTPUT_JSON");
in
{
  imports = [
    inputs.copyparty.nixosModules.default
    ./hardware.nix
    ./disko.nix
  ];

  disko.enableConfig = true;

  boot.loader.systemd-boot.enable = true; # (for UEFI systems only)

  # Set your time zone.
  time.timeZone = "Etc/UTC";

  networking = {
    # Set hostname.
    hostName = "srv-oci-1";
    # Use firewall provided by the underlying cloud provider's infrastructure.
    firewall.enable = false;
  };

  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "k3s_token" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "tailscale/auth_keys/srv_oci_1" = {
        mode = "0400";
        owner = "root";
      };
      "copyparty/accounts/murtaza" = {
        mode = "0400";
        owner = "copyparty";
        group = "copyparty";
      };
      "copyparty/accounts/agent" = {
        mode = "0400";
        owner = "copyparty";
        group = "copyparty";
      };
    };
  };

  platform = {
    # enable flakes & configure gc
    nix.enable = true;
    # setup default users
    users.enable = true;
    # enable openssh
    ssh.enable = true;
    # enable timesyncd service
    synctime.enable = true;
    # tailscale
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/auth_keys/srv_oci_1".path;
    };
    # setup K3S
    k3s = {
      enable = true;
      package = extraArgs.unstable.k3s_1_36;
      role = "agent";
      # nodeIP = infra.oci_instances.value."srv-oci-1".private_ip;
      nodeInternalDNS = "srv-oci-1.tadpole-stonecat.ts.net";
      installLonghornDependencies = true;
    };
  };

  services.copyparty = {
    enable = true;
    settings = {
      i = "10.0.0.11";
      p = 3923;
      hist = "/var/cache/copyparty";
      "no-reload" = true;
      "no-robots" = true;
      "no-thumb" = true;
      "no-dav" = true;
      "no-mtag-ff" = true;
      "vague-403" = true;
      "dotpart" = true;
      rproxy = 1;
      "xff-hdr" = "x-forwarded-for";
      "xff-src" = "10.0.0.0/24,10.42.0.0/16";
    };
    accounts = {
      murtaza.passwordFile = config.sops.secrets."copyparty/accounts/murtaza".path;
      agent.passwordFile = config.sops.secrets."copyparty/accounts/agent".path;
    };
    volumes = {
      "/agents" = {
        path = "/srv/copyparty/agents";
        access = {
          rwmda = "murtaza";
          rw = "agent";
          g = "*";
        };
        flags = {
          fk = 16;
          nohtml = true;
          d2t = true;
          xdev = true;
          xvol = true;
          chmod_d = "0750";
        };
      };
    };
  };

  systemd.tmpfiles.settings."copyparty-root" = {
    "/srv/copyparty".d = {
      mode = "0750";
      user = "copyparty";
      group = "copyparty";
    };
  };

  system.stateVersion = "26.05";
}
