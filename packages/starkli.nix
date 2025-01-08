{
  lib,
  pkgs,
  ...
}: let
  version = "0.3.6";
  src = pkgs.fetchFromGitHub {
    owner = "xJonathanLEI";
    repo = "starkli";
    rev = "v${version}";
    hash = "sha256-T6rvA0siF0FEi7A8H3P9l0ISsQwjRpUw7FYyFu72SMs=";
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
    cargoHash = "sha256-jGsn0dqJncLvs0kL4YptM1MOJUWkSz697/3QmcvPGC4=";

    # Workaround for https://github.com/NixOS/nixpkgs/pull/300532
    cargoDepsHook = ''
      fixStarknetLints() {
        echo cargoDepsCopy=$cargoDepsCopy
        sed -i '/workspace = true/d' $cargoDepsCopy/starknet*/Cargo.toml
        # Remove all lints.
        sed -n '/\[workspace.lints\]/q;p' $cargoDepsCopy/starknet-0.12.0/Cargo.toml
      }
      prePatchHooks+=(fixStarknetLints)
    '';
  }
