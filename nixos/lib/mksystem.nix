{ nixpkgs, inputs }:

name:
{ system
, pkgs
, ...
} @ extraArgs:

nixpkgs.lib.nixosSystem {
  inherit system pkgs;

  specialArgs = {
    inherit nixpkgs inputs extraArgs;
  };

  modules = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    ../modules
    ../hosts/${name}
  ];
}
