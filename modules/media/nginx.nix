{ lib, config, ... }:
let
  transmissionPort = 9091;
  jellyfinPort = 8096;
  jellyseerPort = 5055;
  sonarrPort = 8989;
  radarrPort = 7878;
  prowlarrPort = 9696;
  syncthingPort = 8384;
in
{
  options = {
    media.reverseProxies = {
      enable = lib.mkEnableOption "Server all apps behind NGINX reverse proxy";
      domain = lib.mkOption {
        type = lib.types.str;
        description = "Domain on which the subdomains must be added.";
        example = lib.literalExpression "${config.media.reverseProxies.domain}";
      };
      enableTLS = lib.mkOption {
        type = lib.types.bool;
        description = "Enable TLS";
        default = false;
        example = lib.literalExpression "true";
      };
      useACMEHost = lib.mkOption {
        type = lib.types.str;
        description = "ACME host to use";
        example = lib.literalExpression "*.home.murtazau.xyz";
      };
    };
  };
  config = lib.mkIf config.media.reverseProxies.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = config.media.reverseProxies.enableTLS;
      virtualHosts = {
        "transmission.${config.media.reverseProxies.domain}" = lib.mkIf config.media.transmission.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString transmissionPort}";
              recommendedProxySettings = true;
              extraConfig = ''
                proxy_pass_header X-Transmission-Session-Id;
              '';
            };
          };
        };
        "jellyfin.${config.media.reverseProxies.domain}" = lib.mkIf config.media.jellyfin.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString jellyfinPort}";
              recommendedProxySettings = true;
              extraConfig = ''
                # Disable buffering when the nginx proxy gets very resource heavy
                # upon streaming
                proxy_buffering off;
              '';
            };
            "/socket" = {
              proxyPass = "http://localhost:${toString jellyfinPort}";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
          };
        };
        "jellyseerr.${config.media.reverseProxies.domain}" = lib.mkIf config.media.jellyseerr.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations."/" = {
            proxyPass = "http://localhost:${toString jellyseerPort}";
            recommendedProxySettings = true;
          };
        };
        "sonarr.${config.media.reverseProxies.domain}" = lib.mkIf config.media.arr.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString sonarrPort}";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
            "/api" = {
              proxyPass = "http://localhost:${toString sonarrPort}";
              recommendedProxySettings = true;
            };
          };
        };
        "radarr.${config.media.reverseProxies.domain}" = lib.mkIf config.media.arr.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString radarrPort}";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
            "/api" = {
              proxyPass = "http://localhost:${toString radarrPort}";
              recommendedProxySettings = true;
            };
          };
        };
        "prowlarr.${config.media.reverseProxies.domain}" = lib.mkIf config.media.arr.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString prowlarrPort}";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
            "/api" = {
              proxyPass = "http://localhost:${toString prowlarrPort}";
              recommendedProxySettings = true;
            };
          };
        };
        "syncthing.${config.media.reverseProxies.domain}" = lib.mkIf config.media.syncthing.enable {
          forceSSL = config.media.reverseProxies.enableTLS;
          useACMEHost = config.media.reverseProxies.useACMEHost;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString syncthingPort}";
              recommendedProxySettings = false;
              extraConfig = ''
                proxy_set_header Host 127.0.0.1;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $host;
                proxy_set_header X-Forwarded-Server $host;
              '';
            };
          };
        };
      };
    };
  };
}
