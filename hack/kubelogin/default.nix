{ pkgs }:

let
  src = pkgs.fetchFromGitHub {
    owner = "int128";
    repo = "kubelogin";
    rev = "v1.32.4";
    sha256 = "sha256-zdUtLjILildwSOA5CV1SNzVtMj+Tz1KkHB2MH1SZ8wk=";
  };

  patchedSrc = pkgs.stdenv.mkDerivation {
    name = "kubelogin-patched";
    inherit src;
    patches = [ ./override-oidc-issuer-flag-v1.32.4.patch ];
    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };
in
pkgs.buildGoModule {
  pname = "kubelogin";
  version = "v1.32.4-override-oidc-issuer-flag";
  src = patchedSrc;
  vendorHash = "sha256-5NiGgZLSf/STr888JPsZZqaqXUI+g+26OEKRXp7xS4E=";
  subPackages = [ "." ];
  doCheck = true;
  postInstall = ''
    ln -s $out/bin/kubelogin $out/bin/kubectl-oidc_login
  '';
}
