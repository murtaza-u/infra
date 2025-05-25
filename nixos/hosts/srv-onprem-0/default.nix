{ config, ... }:

{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  disko.enableConfig = true;

  boot = {
    kernelParams = [
      "consoleblank=120" # turn off the screen after 2 minutes of inactivity
    ];
    # Setting GRUB boot loader (legacy bios system).
    loader.grub.enable = true;
  };

  # Disable suspend.
  # We are using a laptop as a server here, so we want it to keep running even
  # when the lid is closed.
  systemd.targets.sleep.enable = false;
  services.logind.lidSwitch = "ignore";

  networking = {
    hostName = "srv-onprem-0";
    nameservers = [
      # Quad9 DNS
      "9.9.9.9"
      "149.112.112.112"
    ];
    # Open ports in the firewall.
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # ssh
        80 # nginx http
        443 # nginx https
      ];
      allowedUDPPorts = [ ];
    };
  };

  # Set your time zone.
  time.timeZone = "Etc/UTC";

  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "transmission/rpc_user" = {
        mode = "0400";
        owner = "transmission";
        group = "transmission";
      };
      "transmission/rpc_password" = {
        mode = "0400";
        owner = "transmission";
        group = "transmission";
      };
      "cf_token" = {
        mode = "0400";
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };
    templates = {
      "transmission/settings.json" = {
        content = ''
          {
            "rpc-username": "${config.sops.placeholder."transmission/rpc_user"}",
            "rpc-password": "${config.sops.placeholder."transmission/rpc_password"}"
          }
        '';
        mode = "0400";
        owner = "transmission";
        group = "transmission";
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
  };

  media = {
    transmission = {
      enable = true;
      credentialsFile = config.sops.templates."transmission/settings.json".path;
    };
    arr.enable = true;
    jellyseerr.enable = true;
    jellyfin.enable = true;
    syncthing.enable = true;
    reverseProxies = {
      enable = true;
      domain = "home.murtazau.xyz";
      enableTLS = true;
      useACMEHost = "home.murtazau.xyz";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      server = "https://acme-v02.api.letsencrypt.org/directory";
      email = "murtaza@murtazau.xyz";
      dnsResolver = "1.1.1.1:53";
      dnsProvider = "cloudflare";
      credentialFiles = {
        "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cf_token".path;
      };
    };
    certs."home.murtazau.xyz" = {
      group = config.services.nginx.group;
      inheritDefaults = true;
      domain = "*.home.murtazau.xyz";
    };
  };

  system.stateVersion = "25.05";
}
