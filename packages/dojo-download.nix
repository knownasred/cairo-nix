# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "1.6.0-alpha.2";
  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256:00r29nslpb3ws9prckv4c134ivyr1lf23i8mvha018p2ka4l0q2q";
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "dojo-artifacts";
    src = sozoTargz;
    phases = ["unpackPhase"];

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];
    buildInputs = with pkgs; [stdenv.cc.cc];

    unpackPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin

      for file in $out/bin/*; do
        if [ -f "$file" ] && [ -x "$file" ]; then
          wrapProgram "$file" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
            pkgs.glibc
          ]}"
        fi
      done
    '';
  };
in {
  dojo = artifacts;
}
