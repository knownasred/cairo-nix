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

  katana = pkgs.stdenv.mkDerivation {
    name = "katana";
    src = artifacts;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp katana $out/bin
    '';
  };

  sozo = pkgs.stdenv.mkDerivation {
    name = "sozo";
    src = artifacts;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp sozo $out/bin
    '';
  };

  torii = pkgs.stdenv.mkDerivation {
    name = "torii";
    src = artifacts;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp torii $out/bin
    '';
  };

}
