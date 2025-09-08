# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "1.7.0-alpha.2";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:0yjbiz1fsjh53qb09594ijnm63pzdkkns42yvwx6sniq1x5xn1zm";
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
