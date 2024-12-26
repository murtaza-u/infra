{ config, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Setting GRUB boot loader.
  boot.loader.grub.enable = true;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  # Disable suspend.
  # We are using a laptop as a server here, so we want it to keep running even
  # when the lid is closed.
  systemd.targets.sleep.enable = false;
  services.logind.lidSwitch = "ignore";

  networking = {
    enableIPv6 = false;
    # Set hostname.
    hostName = "srv-onprem-0";
    nameservers = [
      "94.247.43.254"
      "37.252.191.197"
      "152.53.15.127"
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
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/home/${config.users.users.scout.name}/.ssh/id_ed25519" ];
    secrets = {
      "tailscale/auth_keys/srv_onprem_0" = {
        mode = "0400";
        owner = "root";
      };
      "k3s_token" = {
        mode = "0400";
        owner = "root";
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
      authKeyFile = config.sops.secrets."tailscale/auth_keys/srv_onprem_0".path;
    };
  };

  # K3S.
  services.k3s = {
    enable = true;
    serverAddr = "https://srv-cloud-0:6443";
    gracefulNodeShutdown = {
      enable = true;
      shutdownGracePeriod = "1m30s";
    };
    role = "agent";
    tokenFile = config.sops.secrets."k3s_token".path;
    extraFlags = ''
      --node-ip 100.97.243.45 \
      --kube-proxy-arg metrics-bind-address=0.0.0.0 \
      --flannel-iface tailscale0
    '';
  };
}
