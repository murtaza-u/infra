{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # Set hostname.
  networking.hostName = "srv-cloud-0";

  # Set your time zone.
  time.timeZone = "Etc/UTC";

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

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # ssh
      80 # traefik http
      443 # traefik https
    ];
    allowedUDPPorts = [ ];
  };
}
