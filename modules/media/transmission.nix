{ pkgs, lib, config, ... }:

{
  options = {
    media.transmission = {
      enable = lib.mkEnableOption "Enable Transmission server";
      credentialsFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to a JSON file to be merged with the settings.";
        example = lib.literalExpression "/run/secrets/transmission/settings.json";
      };
    };
  };
  config = lib.mkIf config.media.transmission.enable {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openPeerPorts = true;
      openRPCPort = true;
      downloadDirPermissions = "777";
      credentialsFile = config.media.transmission.credentialsFile;
      settings = rec {
        trash-original-torrent-files = true;
        download-dir = "/media";
        incomplete-dir-enabled = true;
        incomplete-dir = "${download-dir}/.incomplete";
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-authentication-required = true;
      };
    };
  };
}
