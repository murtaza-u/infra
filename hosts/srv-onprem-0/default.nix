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

  # Set hostname.
  networking.hostName = "srv-onprem-0";

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
