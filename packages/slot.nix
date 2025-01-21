{
  lib,
  pkgs,
  ...
}: let
  version = "0.29.0";
  src = pkgs.fetchFromGitHub {
    owner = "cartridge-gg";
    repo = "slot";
    rev = "v${version}";
    hash = "sha256-6MsNbT9uyVMYadavJ05twEg0MngvqnGJnRSzlEwcuvM=";
  };

  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable."1.80.0".minimal;
    rustc = pkgs.rust-bin.stable."1.80.0".minimal;
  };
in
  rustPlatform.buildRustPackage {
    inherit src version;
    pname = "slot";

    nativeBuildInputs = with pkgs; [
      rustPlatform.bindgenHook
      pkg-config
      openssl
      perl
      libclang
      protobuf
    ];

    useFetchCargoVendor = true;
    cargoHash = "sha256-WcUhiojoYliLOh/U3EPhZ6ttLXXotKjBpsV7v2fqOUo=";

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
