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
    cairoVersion,
    srcHash,
    depsHash,
    cairoHash,
  }: let
    cairo-zip = pkgs.fetchurl {
      url = "https://github.com/starkware-libs/cairo/archive/refs/tags/v${cairoVersion}.zip";
      hash = cairoHash;
    };

    src = pkgs.fetchFromGitHub {
      name = "${name}-${version}-src";
      owner = "dojoengine";
      repo = "dojo";
      rev = "v${version}";
      hash = srcHash;
    };

    unpatchedCargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      name = "${name}-${version}-deps";
      hash = depsHash;
    };

    cargoDeps = let
      patchMetadata = pkgs.substituteAll {
        src = ../patches/scarb/scarb-metadata.patch;
        cairoZip = "${cairo-zip}";
      };
      patchScarb = pkgs.substituteAll {
        src = ../patches/scarb/scarb.patch;
        cairoZip = "${cairo-zip}";
      };
    in
      pkgs.stdenv.mkDerivation {
        src = unpatchedCargoDeps;

        name = "${name}-${version}-deps-patch";
        phases = "unpackPhase patchPhase installPhase";

        patchPhase = ''
          BUILD_METADATA_DIR=$(echo ./*/scarb-build-metadata-*)
          BUILD_SCARB_DIR=$(echo ./*/scarb-[0-9]*)
          echo "Applying patch for scarb-build-metadata"
          ${pkgs.patch}/bin/patch --directory $BUILD_METADATA_DIR -p1 < ${patchMetadata}
          echo "Applying patch for scarb"
          ${pkgs.patch}/bin/patch --directory $BUILD_SCARB_DIR -p1 < ${patchScarb}
        '';

        installPhase = "cp -R ./ $out";
      };

    buildCrate = name:
      rustPlatform.buildRustPackage {
        inherit src cargoDeps;

        nativeBuildInputs = with pkgs; [
          pkg-config

          openssl

          rustPlatform.bindgenHook
          libclang

          protobuf
        ];

        # For scarb builds
        CAIRO_ARCHIVE = "${cairo-zip}";

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
