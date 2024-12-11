{
  description = "My homelab configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, sops-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      nixosConfigurations = {
        shiganshina = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              nix.registry.nixpkgs.flake = nixpkgs;
              system.stateVersion = "24.11";
            }
            ./hosts/shiganshina
          ];
        };
        base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              nix.registry.nixpkgs.flake = nixpkgs;
              system.stateVersion = "24.11";
            }
            ./hosts/base
            sops-nix.nixosModules.sops
          ];
        };
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nixpkgs-fmt
          nixos-rebuild
          awscli2
          kubernetes-helm
          kubectl
          fluxcd
          yamllint
          kubeconform
          kubeseal
          kubelogin-oidc
          sops
          ssh-to-age
        ];
      };
    };
}
