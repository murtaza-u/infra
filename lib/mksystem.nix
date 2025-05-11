{ nixpkgs, inputs }:

name:
{ system
, pkgs
}:

nixpkgs.lib.nixosSystem {
  inherit system pkgs;

  specialArgs = {
    inherit nixpkgs inputs;
  };

  modules = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    ../modules
    ../hosts/${name}
  ];
}
