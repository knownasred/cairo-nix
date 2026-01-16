# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "1.8.0";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:1lm7xld3f3qzd06h2qs2f9dn5azmpp6vf7acwyprnp4hf769a02i";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "dojo-artifacts";
    src = sozoTargz;
    phases = ["unpackPhase" "installCheckPhase"];

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];
    buildInputs = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
    doInstallCheck = true;

    unpackPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin

      # Run autoPatchelf to fix the interpreter and add missing libraries
      autoPatchelf $out/bin

      runHook postInstall
    '';

    installCheckPhase = ''
      echo "Validating sozo..."
      $out/bin/sozo --version || (echo "Error: sozo failed to launch" && exit 1)
    '';
  };
in {
  dojo = artifacts;
}
