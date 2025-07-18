# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "1.6.0-alpha.2";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:00r29nslpb3ws9prckv4c134ivyr1lf23i8mvha018p2ka4l0q2q";
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

      echo "Validating dojo-language-server..."
      $out/bin/dojo-language-server --version || (echo "Error: dojo-language-server failed to launch" && exit 1)
    '';
  };
in {
  dojo = artifacts;
}
