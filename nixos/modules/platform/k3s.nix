{ pkgs, lib, config, ... }:
let
  isServer = config.platform.k3s.role == "server";
  hasNodeIP = config.platform.k3s.nodeIP != null;
  hasNodeInternalDNS = config.platform.k3s.nodeInternalDNS != null;
  authenticationConfig = lib.generators.toYAML { } {
    apiVersion = "apiserver.config.k8s.io/v1beta1";
    kind = "AuthenticationConfiguration";
    jwt = [
      {
        issuer = {
          url = config.platform.k3s.oidcIssuerURL;
          discoveryURL = config.platform.k3s.oidcDiscoveryURL;
          audiences = config.platform.k3s.oidcAudiences;
          audienceMatchPolicy = "MatchAny";
        };
        claimMappings = {
          username = {
            expression = config.platform.k3s.oidcUsernameClaimExpression;
          };
          groups = {
            expression = config.platform.k3s.oidcGroupsClaimExpression;
          };
        };
      }
    ];
  };
in
{
  options = {
    platform.k3s = {
      enable = lib.mkEnableOption "Setup k3s node";
      package = lib.mkPackageOption pkgs "k3s" { };
      role = lib.mkOption {
        description = ''
          Whether k3s should run as a server or agent.

          If it's a server:

          - By default it also runs workloads as an agent.
          - Starts by default as a standalone server using an embedded sqlite datastore.
          - Configure `clusterInit = true` to switch over to embedded etcd datastore and enable HA mode.
          - Configure `serverAddr` to join an already-initialized HA cluster.

          If it's an agent:

          - `serverAddr` is required.
        '';
        default = "server";
        type = lib.types.enum [
          "server"
          "agent"
        ];
      };
      isBootstrapNode = lib.mkOption {
        type = lib.types.bool;
        description = ''
          Node will be responsible to bootstrap k3s control-plane.
          Node's `role` must be `server`.
        '';
        default = false;
      };
      nodeIP = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "IPv4/IPv6 addresses to advertise for node.";
        default = null;
      };
      nodeInternalDNS = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Internal DNS addresses to advertise for node";
        default = null;
      };
      oidcIssuerURL = lib.mkOption {
        type = lib.types.str;
        description = ''
          Required.

          The URL of the OpenID issuer, only HTTPS scheme will be accepted. If
          set, it will be used to verify the OIDC JSON Web Token (JWT).
        '';
        example = "https://identity.oraclecloud.com/";
      };
      oidcDiscoveryURL = lib.mkOption {
        type = lib.types.str;
        description = ''
          Optional.

          Useful if the discovery url is not the same as the issuer url.
        '';
        example = "https://idcs-06327910780595044767776543574386.identity.oraclecloud.com/.well-known/openid-configuration";
      };
      oidcClientID = lib.mkOption {
        type = lib.types.str;
        description = ''
          Required.

          The client ID for the OpenID Connect client.
        '';
      };
      oidcAudiences = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of OIDC JWT token audiences";
      };
      oidcExtraScope = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        description = ''
          Required.

          The client ID for the OpenID Connect client.
        '';
        example = [ "email" "groups" ];
      };
      oidcUsernameClaimExpression = lib.mkOption {
        type = lib.types.str;
        description = ''
          Optional.

          CEL expression to capture the OpenID username claim.
        '';
        default = "claims.sub";
      };
      oidcGroupsClaimExpression = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = ''
          Optional.

          CEL expression to capture the OpenID user groups.
        '';
        default = "claims.groups";
      };
      oidcAdminSubjects = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            kind = lib.mkOption {
              type = lib.types.enum [ "Group" "User" ];
              default = "Group";
              description = "The kind of the subject: 'Group' or 'User'";
            };
            name = lib.mkOption {
              type = lib.types.str;
              description = "The name of the group or user";
            };
          };
        });
        description = "List of OIDC admin subjects";
      };
      installLonghornDependencies = lib.mkOption {
        type = lib.types.bool;
        description = ''
          Install longhorn dependencies as described in
          https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/examples/STORAGE.md
        '';
        default = false;
      };
    };
  };
  config = lib.mkIf config.platform.k3s.enable {
    assertions = [
      (lib.mkIf (!isServer) {
        assertion = !config.platform.k3s.isBootstrapNode;
        message = "Only server nodes can be responsible for bootstrapping";
      })
      (lib.mkIf (isServer && config.platform.k3s.isBootstrapNode) {
        assertion = lib.length config.platform.k3s.oidcAdminSubjects != 0;
        message = "platform.k3s.oidcAdminSubjects must not be empty for bootstrap node";
      })
    ];
    environment.etc = lib.mkIf isServer {
      "k3s/authentication-configuration.yaml".text = authenticationConfig;
    };
    environment.systemPackages = lib.mkIf config.platform.k3s.installLonghornDependencies [ pkgs.nfs-utils ];
    services.openiscsi = lib.mkIf config.platform.k3s.installLonghornDependencies {
      enable = true;
      name = "${config.networking.hostName}-initiatorhost";
    };
    services.k3s = {
      enable = true;
      package = config.platform.k3s.package;
      tokenFile = config.sops.secrets."k3s_token".path;
      gracefulNodeShutdown = {
        enable = true;
        shutdownGracePeriod = "1m30s";
        shutdownGracePeriodCriticalPods = "1m";
      };
      role = config.platform.k3s.role;
      serverAddr = lib.mkIf (!config.platform.k3s.isBootstrapNode) "https://k3s.murtazau.xyz:6443";
      extraFlags = [
        "--kube-proxy-arg metrics-bind-address=0.0.0.0"
      ] ++ lib.optionals hasNodeIP [
        "--node-ip ${config.platform.k3s.nodeIP}"
      ] ++ lib.optionals hasNodeInternalDNS [
        "--node-internal-dns ${config.platform.k3s.nodeInternalDNS}"
      ] ++ lib.optionals isServer [
        "--disable local-storage"
        "--secrets-encryption"
        "--tls-san k3s.murtazau.xyz"
        "--kube-apiserver-arg anonymous-auth=false"
        "--kube-apiserver-arg authentication-config=${config.environment.etc."k3s/authentication-configuration.yaml".source}"
        "--kube-controller-manager-arg bind-address=0.0.0.0"
        "--kube-scheduler-arg bind-address=0.0.0.0"
      ] ++ lib.optionals config.platform.tailscale.enable [
        "--flannel-iface tailscale0"
      ];
      manifests.oidc-cluster-role-binding = lib.mkIf isServer {
        enable = true;
        target = "oidc-admin-cluster-role-binding.yaml";
        content = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRoleBinding";
          metadata = {
            name = "oidc-admin";
          };
          subjects = config.platform.k3s.oidcAdminSubjects;
          roleRef = {
            kind = "ClusterRole";
            name = "cluster-admin";
            apiGroup = "rbac.authorization.k8s.io";
          };
        };
      };
    };
  };
}
