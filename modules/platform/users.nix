{ lib, config, ... }:

{
  options = {
    platform.users.enable = lib.mkEnableOption "Set up users";
  };
  config = lib.mkIf config.platform.users.enable {
    # We have two users on the system.
    #
    # `murtaza`: normal user
    # `scout`: used in CI/CD workflows
    users.users = {
      murtaza = {
        isNormalUser = true;
        initialPassword = "ihatenix";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMl6JwHVx+8qlgfeB18mNSAPvIgT9j8P9j8eNyF6GJ/3"
        ];
      };
      scout = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWGnWp1gsGnzlbZh6ie4IZE1p226lkzGCzfGgApYV5C"
        ];
      };
    };

    # Enable password-less sudo for `scout` user.
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
  };
}
