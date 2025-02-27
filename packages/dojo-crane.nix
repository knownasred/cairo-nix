{
  lib,
  pkgs,
  crane,
  fenix,
  ...
}: {
  version,
  rustVersion,
  cairoVersion,
  srcHash,
  depsHash,
  cairoHash,
  patches ? false,
}: let
  inherit (pkgs) lib;

  name = "dojo-crane-${version}";

  craneLib = crane.mkLib pkgs;

  unpatchedSrc = pkgs.fetchFromGitHub {
    name = "${name}-${version}-src";
    owner = "dojoengine";
    repo = "dojo";
    rev = "v${version}";
    hash = srcHash;
  };

  dojoPatch = pkgs.substituteAll {
    src = ../patches/dojo_1_2_1.patch;
  };

  src = pkgs.stdenv.mkDerivation {
    src = unpatchedSrc;
    name = "${name}-${version}-src-patched";

    installPhase = "cp -R ./ $out";

    patches = [dojoPatch];
  };

  cairo-zip = pkgs.fetchurl {
    url = "https://github.com/starkware-libs/cairo/archive/refs/tags/v${cairoVersion}.zip";
    hash = cairoHash;
  };

  commonArgs = {
    inherit src;
    strictDeps = true;
    pname = "dojo";

    buildInputs = with pkgs;
      [
        curl
        openssl
        libclang
        libclang.lib

        protobuf
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        # Additional darwin specific inputs can be set here
        pkgs.libiconv
      ];

    nativeBuildInputs = with pkgs; [
      rustPlatform.bindgenHook
      pkg-config
    ];

    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    CAIRO_ARCHIVE = "${cairo-zip}";
    PROTOC = "${pkgs.protobuf}/bin/protoc";

    # Additional environment variables can be set directly
    # MY_CUSTOM_VAR = "some value";
  };

  # Override for scarb-metadata (pin versions for now)
  isScarb = p:
    lib.hasPrefix
    "git+https://github.com/dojoengine/scarb"
    p.source;

  # Prepare the patched vendor directory
  cargoVendorDir = craneLib.vendorCargoDeps (commonArgs
    // {
      pname = "dojo-deps-vendor";
      # Use this function to override crates coming from git dependencies
      overrideVendorGitCheckout = ps: drv:
      # For example, patch a specific repository and tag, in this case num_cpus-1.13.1
        if lib.any (p: (isScarb p)) ps
        then
          drv.overrideAttrs
          (
            _old: let
              pss = lib.findFirst (p: (p.name == "scarb-build-metadata")) null ps;
              scarb = lib.findFirst (p: (p.name == "scarb")) null ps;
            in {
              patches = builtins.trace "Reached patch!" [
                (pkgs.substituteAll {
                  src = ./overrides/scarb.patch;
                  cairoZip = "${cairo-zip}";
                })
              ];

              # Similarly we can also run additional hooks to make changes
              postInstall = ''
                echo "==========="
                echo "-> " $CAIRO_ARCHIVE
                SCARB_META_OUT_DIR=${pss.name}-${pss.version}
                cp $src/Cargo.lock $out/$SCARB_META_OUT_DIR/Cargo.lock
                echo --- Fix values
                CAIRO_VERSION=$(${pkgs.toml-cli}/bin/toml get Cargo.lock . | jq '.package[] | select(.name == "cairo-lang-compiler").version' -r)
                sed -i -e "s/{{cairo_version}}/$CAIRO_VERSION/g" $out/$SCARB_META_OUT_DIR/build.rs
                sed -i -e "s/{{version}}/${scarb.version}/g" $out/$SCARB_META_OUT_DIR/build.rs
                echo "==========="
              '';
            }
          )
        else
          # Nothing to change, leave the derivations as is
          drv;
    });

  cargoArtifacts = craneLib.buildDepsOnly (commonArgs
    // {
      pname = "dojo-deps";
      inherit cargoVendorDir;
    });
in
  craneLib.buildPackage {
    inherit cargoArtifacts src;
    inherit cargoVendorDir;
    inherit (craneLib.crateNameFromCargoToml {inherit src;}) version;
    pname = "dojo-stack";
    doCheck = false;
  }
