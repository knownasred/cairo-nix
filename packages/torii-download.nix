{
  lib,
  pkgs,
  ...
}: let
  version = "1.6.0-alpha.1";
  toriiTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/torii/releases/download/v${version}/torii_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:0crww8kffyi2iq1r3z92n7sy7v5gi723x378spqk4cr46v7wnaqm";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "torii-artifacts";
    src = toriiTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };
in
  pkgs.stdenv.mkDerivation rec {
    name = "torii";
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
