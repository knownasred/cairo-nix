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
in
  pkgs.stdenv.mkDerivation {
    name = "scarb";
    src = sozoTargz;

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];

    buildInputs = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];

    unpackPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin

      # Move everyting from the sozo-* subdir to the root
      mv $out/bin/scarb-*/bin/* $out/bin/

      rm -r $out/bin/scarb-*

      # Run autoPatchelf to fix the interpreter and add missing libraries
      autoPatchelf $out/bin

      runHook postInstall
    '';
  }
