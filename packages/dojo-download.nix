# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "1.5.1";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:1sbs29l74bwhapqqzf6ckfds7aj7qz4h84q2iyi1wcbr0hmy0czw";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "dojo-artifacts";
    src = sozoTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };

  libraries = with pkgs;
    lib.makeLibraryPath [
      glibc
      zlib
    ];
in {
  dojo-language-server = pkgs.stdenv.mkDerivation {
    name = "dojo-language-server";
    src = artifacts;
    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      cp dojo-language-server $out/bin
    '';
  };

  katana = pkgs.stdenv.mkDerivation rec {
    name = "katana";
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
  };

  sozo = pkgs.stdenv.mkDerivation rec {
    name = "sozo";
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
  };

  torii = pkgs.stdenv.mkDerivation rec {
    name = "torii";
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
  };
}
