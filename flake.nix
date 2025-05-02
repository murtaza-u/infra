{
  description = "Lab on a Shoestring";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = p: builtins.elem (pkgs.lib.getName p) [
              "terraform"
            ];
          };
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nixd
              nixpkgs-fmt
              terraform
              terraform-ls
              tflint
              sops
              ssh-to-age
              yamlfmt
              yamllint
              kubectl
              fluxcd
              kubernetes-helm
              kustomize
              kubeseal
            ];
          };
        }
      )
    //
    {
      nixosConfigurations = {
        srv-cloud-0 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          pkgs = import nixpkgs { system = "aarch64-linux"; };
          modules = [
            {
              nix.registry.nixpkgs.flake = nixpkgs;
              system.stateVersion = "24.11";
            }
            ./hosts/srv-cloud-0
            ./modules
            inputs.sops-nix.nixosModules.sops
          ];
        };
        srv-onprem-0 = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.permittedInsecurePackages = [
              "dotnet-sdk-6.0.428"
              "aspnetcore-runtime-6.0.36"
            ];
          };
          modules = [
            {
              nix.registry.nixpkgs.flake = nixpkgs;
              system.stateVersion = "24.11";
            }
            ./hosts/srv-onprem-0
            ./modules
            inputs.sops-nix.nixosModules.sops
          ];
        };
      };
    };
}
