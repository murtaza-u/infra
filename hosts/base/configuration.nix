{ lib, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "scout" ]; # `scout` is used for CD
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "base"; # Define your hostname.
    # Assigning static ip address to host.
    interfaces.enp9s0 = {
      ipv4.addresses = [{
        address = "192.168.29.5";
        prefixLength = 24;
      }];
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # We have two users on the system.
  #
  # `murtaza`: normal user
  # `scout`: continuous deployment
  users.users = {
    murtaza = {
      isNormalUser = true;
      initialPassword = "ihatenix";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuDtCTSUzgA57AIh+xePzFRJoi6zMYsKVkKElWNPquS"
      ];
    };
    scout = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlvxYvoXreZ+iNU5ia0QkjYIIVwAUD9z7b/P1eoF0P+"
      ];
    };
  };

  # Enable password-less sudo for `scout`.
  security.sudo.extraRules = [
    {
      users = [ "scout" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [ nvi ];

  # OpenSSH.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = false;
    };
  };

  # Sync system clock.
  services.chrony = {
    enable = true;
    enableNTS = true;
  };

  # Disable suspend.
  # We are using a laptop as a server here, so we want it to keep running even
  # when the lid is closed.
  systemd.targets.sleep.enable = false;
  services.logind.lidSwitch = "ignore";

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22 # ssh
  ];
  networking.firewall.allowedUDPPorts = [ ];
}
