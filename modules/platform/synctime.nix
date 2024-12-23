{ lib, config, ... }:

{
  options = {
    platform.synctime.enable = lib.mkEnableOption "Keep system time in sync with NTP servers";
  };
  config = lib.mkIf config.platform.synctime.enable {
    services.timesyncd = {
      enable = true;
      servers = [
        "0.pool.ntp.org"
        "1.pool.ntp.org"
        "2.pool.ntp.org"
        "3.pool.ntp.org"
      ];
      fallbackServers = [
        "time.google.com"
        "amazon.pool.ntp.org"
        "time.cloudflare.com"
      ];
    };
  };
}
