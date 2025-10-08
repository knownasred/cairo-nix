# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "2.12.2";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/software-mansion/scarb/releases/download/v${version}/scarb-v${version}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256:0l7741g9ggl4l062zd1z5410b4hfz4sj4hw7pa5nmcg5jlpwhwfy";
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

      # Run autoPatchelf to fix the interpreter and add missing libraries
      autoPatchelf $out/bin
    '';

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];

    buildInputs = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  }
