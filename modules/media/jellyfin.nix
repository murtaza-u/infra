{ lib, config, ... }:

{
  options = {
    media.jellyfin = {
      enable = lib.mkEnableOption "Enable Jellyfin";
    };
  };
  config = lib.mkIf config.media.jellyfin.enable {
    services.jellyfin.enable = true;
  };
}
