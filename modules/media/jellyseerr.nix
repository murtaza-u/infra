{ lib, config, ... }:

{
  options = {
    media.jellyseerr = {
      enable = lib.mkEnableOption "Enable Jellyseerr";
    };
  };
  config = lib.mkIf config.media.jellyseerr.enable {
    services.jellyseerr.enable = true;
  };
}
