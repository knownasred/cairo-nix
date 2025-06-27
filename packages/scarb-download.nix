# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "2.11.4";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/software-mansion/scarb/releases/download/v${version}/scarb-v${version}-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "sha256:14isjglp13jzgbn6ycpfprnjhrpvhandzfkj4va5c7k7balik749";
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
