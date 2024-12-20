{ lib, config, ... }:

{
  options = {
    platform.ssh.enable = lib.mkEnableOption "Setup SSH";
  };
  config = lib.mkIf config.platform.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "no";
        PasswordAuthentication = false;
      };
    };
  };
}
