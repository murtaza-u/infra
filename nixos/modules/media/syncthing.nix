{ lib, config, ... }:

{
  options = {
    media.syncthing = {
      enable = lib.mkEnableOption "Enable syncthing server";
    };
  };
  config = lib.mkIf config.media.syncthing.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      overrideDevices = false;
      overrideFolders = false;
      guiAddress = "localhost:8384";
      settings.folders = {
        "/media/family/movies" = rec {
          type = "receiveonly";
          id = "family-movies";
          label = id;
          ignoreDelete = true;
        };
        "/media/family/tvshows" = rec {
          type = "receiveonly";
          id = "family-tvshows";
          label = id;
          ignoreDelete = true;
        };
        "/media/private/movies" = rec {
          type = "receiveonly";
          id = "private-movies";
          label = id;
          ignoreDelete = true;
        };
        "/media/private/tvshows" = rec {
          type = "receiveonly";
          id = "private-tvshows";
          label = id;
          ignoreDelete = true;
        };
      };
    };
  };
}
