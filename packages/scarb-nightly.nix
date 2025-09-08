# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "dev-2025-09-05";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/software-mansion/scarb-nightlies/releases/download/${version}/scarb-${version}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256:1ghl2zxqnyb0778vf1msvk096vvp7q5mgya2ibkb8aq5630qg637";
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

      ls -l $out/bin

      rm -r $out/bin/scarb-*/

      # Run autoPatchelf to fix the interpreter and add missing libraries
      autoPatchelf $out/bin

      runHook postInstall
    '';
  }
