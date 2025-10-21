{ lib, config, ... }:

{
  options = {
    media.aria2 = {
      enable = lib.mkEnableOption "Enable aria2 daemon";
    };
  };
  config = lib.mkIf config.media.aria2.enable {
    services.aria2 = {
      enable = true;
      rpcSecretFile = config.sops.secrets."aria2_rpc_token".path;
    };
  };
}
