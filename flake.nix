{
  description = "My homelab on AWS";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  outputs = { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      nixosConfigurations.shiganshina = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            nix.registry.nixpkgs.flake = nixpkgs;
            system.stateVersion = "24.05";
          }
          ./hosts/shiganshina
        ];
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
        ];
      };
    };
}
