{ modulesPath, config, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # Set your time zone.
  time.timeZone = "Etc/UTC";

  networking = {
    # Set hostname.
    hostName = "srv-cloud-0";
    # Open ports in the firewall.
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # ssh
        80 # traefik http
        443 # traefik https
      ];
      allowedUDPPorts = [ ];
    };
  };

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/home/${config.users.users.scout.name}/.ssh/id_ed25519" ];
    secrets."tailscale/auth_keys/srv_cloud_0" = {
      mode = "0400";
      owner = "root";
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
      authKeyFile = config.sops.secrets."tailscale/auth_keys/srv_cloud_0".path;
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
    role = "server";
    extraFlags = ''
      --tls-san srv-cloud-0 \
      --secrets-encryption \
      --node-ip 100.122.27.100 \
      --kube-controller-manager-arg bind-address=0.0.0.0 \
      --kube-scheduler-arg bind-address=0.0.0.0 \
      --kube-proxy-arg metrics-bind-address=0.0.0.0 \
      --flannel-iface tailscale0
    '';
  };
}
