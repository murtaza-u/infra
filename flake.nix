{
  description = "Lab on a Shoestring";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    unstable-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-registry = {
      url = "github:nixos/flake-registry";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko?ref=v1.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }@inputs:
    let
      mkSystem = import ./nixos/lib/mksystem.nix {
        inherit nixpkgs inputs;
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          unstable = import inputs.unstable-nixpkgs {
            inherit system;
            config.allowUnfreePredicate = p: builtins.elem (pkgs.lib.getName p) [
              "terraform"
            ];
          };
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          devShells.default = pkgs.mkShell {
            packages = with unstable; [
              nixd
              nixpkgs-fmt
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
              oci-cli
              terraform-ls
              terraform
              (import ./hack/kubelogin { pkgs = unstable; })
            ];
          };
        }
      )
    //
    {
      nixosConfigurations = {
        srv-oci-0 = mkSystem "srv-oci-0" rec {
          system = "aarch64-linux";
          pkgs = import nixpkgs { inherit system; };
          unstable = import inputs.unstable-nixpkgs { inherit system; };
        };
        srv-onprem-0 = mkSystem "srv-onprem-0" rec {
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.permittedInsecurePackages = [
              "dotnet-sdk-6.0.428"
              "aspnetcore-runtime-6.0.36"
            ];
          };
        };
      };
    };
}
