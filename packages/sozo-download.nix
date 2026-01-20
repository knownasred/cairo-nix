{
  lib,
  pkgs,
  ...
}: let
  version = "1.8.5";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/sozo%2Fv${version}/sozo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:1jffimx892ni4zyv4k1qacxxnr283230n7d33zwhicy1q0mjva3m";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "sozo-artifacts";
    src = sozoTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };
in
  pkgs.stdenv.mkDerivation rec {
    name = "sozo";
    inherit version;
    src = artifacts;

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];
    buildInputs = with pkgs; [stdenv.cc.cc zlib];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp ${name} $out/bin

      wrapProgram $out/bin/${name} \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        pkgs.glibc
      ]}"

      runHook postInstall
    '';
  }
