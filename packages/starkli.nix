{
  lib,
  pkgs,
  ...
}: let
  version = "0.3.7";
  src = pkgs.fetchFromGitHub {
    owner = "xJonathanLEI";
    repo = "starkli";
    rev = "v${version}";
    hash = "sha256-q1H/B0WRM9/ZHODbEDuBu9RhscrBMKqAgIbFDwrX9cM=";
  };

  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable."1.83.0".minimal;
    rustc = pkgs.rust-bin.stable."1.83.0".minimal;
  };
in
  rustPlatform.buildRustPackage {
    inherit src version;
    pname = "starkli";

    nativeBuildInputs = with pkgs; [
      pkg-config
      openssl
      perl
    ];

    # https://discourse.nixos.org/t/rust-openssl-woes/12340
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

    useFetchCargoVendor = true;
    cargoHash = "sha256-6pB/bklkWlTcGRUm1fb1Qi0gOtGS34kKj/ec0T/+VS0=";

    # Workaround for https://github.com/NixOS/nixpkgs/pull/300532
    cargoDepsHook = ''
      fixStarknetLints() {
        echo cargoDepsCopy=$cargoDepsCopy
        sed -i '/workspace = true/d' $cargoDepsCopy/*/starknet*/Cargo.toml
        # Remove all lints.
        sed -n '/\[workspace.lints\]/q;p' $cargoDepsCopy/*/starknet-0.12.0/Cargo.toml
      }
      prePatchHooks+=(fixStarknetLints)
    '';
  }
