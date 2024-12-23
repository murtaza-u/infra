{ lib, config, ... }:

{
  options = {
    platform.tailscale = {
      enable = lib.mkEnableOption "Enable tailscale client daemon";
      authKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Tailscale auth key file path";
        example = lib.literalExpression "/run/secrets/tailscale/auth_key";
      };
    };
  };
  config = lib.mkIf config.platform.tailscale.enable {
    services.tailscale = {
      enable = true;
      disableTaildrop = true;
      authKeyFile = config.platform.tailscale.authKeyFile;
    };
  };
}
