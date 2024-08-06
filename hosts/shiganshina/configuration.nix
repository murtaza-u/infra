{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

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

  networking.hostName = "shiganshina";

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # We have two users on the system.
  #
  # `eren`: normal user
  # `scout`: continuous deployment
  users.users = {
    eren = {
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

  # K3S.
  services.k3s.enable = true;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22 # ssh
    80 # traefik http
    443 # traefik https
    6443 # kubernetes apiserver
  ];
  # networking.firewall.allowedUDPPorts = [ ];
}
