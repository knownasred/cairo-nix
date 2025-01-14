{
  lib,
  pkgs,
  ...
}: let
  name = "dojo";

  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable."1.80.0".minimal;
    rustc = pkgs.rust-bin.stable."1.80.0".minimal;
  };

  mkDojo = {
    version,
    srcHash,
    depsHash,
  }: let
    src = pkgs.fetchFromGitHub {
      name = "${name}-${version}-src";
      owner = "dojoengine";
      repo = "dojo";
      rev = "v${version}";
      hash = srcHash;
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      name = "${name}-${version}-deps";
      hash = depsHash;
    };

    buildCrate = name:
      rustPlatform.buildRustPackage {
        inherit src cargoDeps;

        nativeBuildInputs = with pkgs; [
          pkg-config

          openssl
          libclang
          libclang.lib

          protobuf
        ];

        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";

        name = name;

        cargoBuildOptions = ["-p" name];
        cargoTestOptions = ["-p" name];
      };
  in {
    dojo-language-server = buildCrate "dojo-language-server";
    katana = buildCrate "katana";
    sozo = buildCrate "sozo";
    torii = buildCrate "torii";
  };

  versions = lib.importJSON ./dojoVersions.json;

  toolchains = builtins.listToAttrs (builtins.map (v: {
      name = v.version;
      value = mkDojo v;
    })
    versions);
in {
  dojo = toolchains;
}
