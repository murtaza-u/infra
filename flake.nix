{
  description = "Lab on a Shoestring";
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
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
            "terraform"
          ];
          permittedInsecurePackages = [
            "dotnet-sdk-6.0.428"
            "aspnetcore-runtime-6.0.36"
          ];
        };
      };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
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
            sops-nix.nixosModules.sops
          ];
        };
        srv-onprem-0 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [
            {
              nix.registry.nixpkgs.flake = nixpkgs;
              system.stateVersion = "24.11";
            }
            ./hosts/srv-onprem-0
            ./modules
            sops-nix.nixosModules.sops
          ];
        };
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nixpkgs-fmt
          terraform
          terraform-ls
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
    };
}
