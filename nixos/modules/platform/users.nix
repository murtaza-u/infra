{ lib, config, ... }:

{
  options = {
    platform.users.enable = lib.mkEnableOption "Set up users";
  };
  config = lib.mkIf config.platform.users.enable {
    # We have two users on the system.
    #
    # `murtaza`: normal user
    # `ops`: used in CI/CD workflows
    users.users = {
      murtaza = {
        isNormalUser = true;
        initialPassword = "ihatenix";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInL6jKG3tfNfX3E5xsrnqOcnSVTz+gSJOm+8tO7qjCU"
        ];
      };
      ops = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK0SilUNT21sJMMxgmdmWSuAZAxdhQfeNOP5kLfSeYL+"
        ];
      };
    };

    # Enable password-less sudo for `ops` user.
    security.sudo.extraRules = [
      {
        users = [ "ops" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
