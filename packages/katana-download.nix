{
  lib,
  pkgs,
  ...
}: let
  version = "1.6.3";
  katanaTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/katana/releases/download/v${version}/katana_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:0j5cdqq2kjvc1jfzw7aap1sfk9xxklrfjv8hm1iv040jxldffvfd";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "katana-artifacts";
    src = katanaTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };
in
  pkgs.stdenv.mkDerivation rec {
    name = "katana";
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
