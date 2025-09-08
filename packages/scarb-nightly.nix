# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "nightly-2025-07-19";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/software-mansion/scarb-nightlies/releases/download/${version}/scarb-${version}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256:1fx39rhjmfm75xax4m6374in73yk253f7b5hb56s46ckbf2938sl";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "scarb-artifacts";
    src = sozoTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };
in
  pkgs.stdenv.mkDerivation {
    name = "scarb";
    src = artifacts;
    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      mv ./scarb-*/* $out
    '';
  }
