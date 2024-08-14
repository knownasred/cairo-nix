# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{ lib
, pkgs
, ...
}:
let
  version = "0.7.3";
  buildTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:1xwkrr9sc9aahhnkw10s2g3889374550mpzlhyv4pixiy98sihcr";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "dojo-artifacts";
    src = buildTargz;
    phases = [ "unpackPhase" ];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };
in
{
  dojo-language-server = pkgs.stdenv.mkDerivation {
    name = "dojo-language-server";
    src = artifacts;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp dojo-language-server $out/bin
    '';
  };

  katana = pkgs.stdenv.mkDerivation rec {
    name = "katana";
    src = artifacts;

    nativeBuildInputs = with pkgs; [ autoPatchelfHook makeWrapper ];
    buildInputs = with pkgs; [ stdenv.cc.cc ];

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

    nativeBuildInputs = with pkgs; [ autoPatchelfHook makeWrapper ];
    buildInputs = with pkgs; [ stdenv.cc.cc ];

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

    nativeBuildInputs = with pkgs; [ autoPatchelfHook makeWrapper ];
    buildInputs = with pkgs; [ stdenv.cc.cc ];

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
