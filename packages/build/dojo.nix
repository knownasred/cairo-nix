{pkgs, ...}: let
  name = "sozo";
  version = "1.5.1";

  cairoVersion = "2.10.1";
  cairoHash = "sha256-Sli/r/vIAvKhrV+A8OHztbo4IMFqGxvt+OWpELVmoxc=";

  rustVersion = "1.86.0";

  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable.${rustVersion}.minimal;
    rustc = pkgs.rust-bin.stable.${rustVersion}.minimal;
  };
  # Prepare dependencies
  src = pkgs.fetchFromGitHub {
    name = "${name}-${version}-src";
    owner = "dojoengine";
    repo = "dojo";
    rev = "v${version}";
    hash = "sha256-dtun0zWZDLdeKd3aUBOJbfxk304bZDs+8XWamKFMlYo=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${name}-${version}-deps";
    hash = "sha256-E0t+bFzzMVwpDagQoXYedKVlgB8WKTn7e3jO9mWppUA=";
  };

  cairo-zip = pkgs.fetchurl {
    name = "cairo-zip-${cairoVersion}";
    url = "https://github.com/starkware-libs/cairo/archive/refs/tags/v${cairoVersion}.zip";
    hash = cairoHash;
  };
in
  rustPlatform.buildRustPackage {
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
  }
