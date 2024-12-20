{ lib, config, ... }:

{
  options = {
    platform.nix.enable = lib.mkEnableOption "Setup default nix config";
  };
  config = lib.mkIf config.platform.nix.enable {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "scout" ]; # `scout` is used in CI/CD workflows
    };
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };
}
