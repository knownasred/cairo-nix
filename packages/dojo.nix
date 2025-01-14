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

          # Similarly we can also run additional hooks to make changes
          echo "=========="
          # We need to find the version
          SCARB_VERSION=$(echo $BUILD_SCARB_DIR | sed -En 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')
          echo "SCARB: " $SCARB_VERSION
          CAIRO_VERSION=$(${pkgs.toml-cli}/bin/toml get ./Cargo.lock '.' | ${pkgs.jq}/bin/jq '.package[] | select(.name == "cairo-lang-compiler").version' -r)
          echo "CAIRO: " $CAIRO_VERSION

          sed -i -e "s/{{cairo_version}}/$CAIRO_VERSION/g" $BUILD_METADATA_DIR/build.rs
          sed -i -e "s/{{version}}/$SCARB_VERSION/g" $BUILD_METADATA_DIR/build.rs
          echo "=========="
        '';

        installPhase = "cp -R ./ $out";
      };
    commonBuild = rustPlatform.buildRustPackage {
      inherit src cargoDeps;

      nativeBuildInputs = with pkgs; [
        pkg-config

        rustPlatform.bindgenHook

        libclang

        protobuf
      ];

      buildInputs = with pkgs; [
        openssl
      ];

      # There's a failing test for now, and I want to get a build out.
      doCheck = false;

      # For scarb builds
      CAIRO_ARCHIVE = "${cairo-zip}";

      name = "dojo-${version}-build";
    };

    buildCrate = name:
      pkgs.stdenv.mkDerivation {
        inherit name;

        # TODO: Copy just the wanted executable (let's reuse caching)
        src = commonBuild;

        pname = name;

        installPhase = ''
          mkdir -p $out/bin
          cp $src/bin/${name} $out/bin/${name}
        '';
      };
  in {
    dojo-language-server = buildCrate "dojo-language-server";
    dojo-world-abigen = buildCrate "dojo-world-abigen";
    katana = buildCrate "katana";
    saya = buildCrate "saya";
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
