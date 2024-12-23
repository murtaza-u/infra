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
        config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
          "terraform"
        ];
      };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      nixosConfigurations.srv-cloud-0 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
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
