{ lib, config, ... }:

{
  options = {
    media.arr = {
      enable = lib.mkEnableOption "Enable ARR stack";
    };
  };
  config = lib.mkIf config.media.arr.enable {
    services = {
      sonarr.enable = true;
      radarr.enable = true;
      prowlarr.enable = true;
    };
  };
}
