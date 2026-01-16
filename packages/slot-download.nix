# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "0.56.0";
  buildTargz = builtins.fetchurl {
    url = "https://github.com/cartridge-gg/slot/releases/download/v${version}/slot_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:03c06c6b4j2prh144vrvz2qwimxj895435niq24pryydzmkjxfd3";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "slot-artifacts";
    src = buildTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };
in
  pkgs.stdenv.mkDerivation rec {
    name = "slot";
    src = artifacts;

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];
    buildInputs = with pkgs; [stdenv.cc.cc];

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
