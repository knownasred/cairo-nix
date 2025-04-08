{
  description = "Cairo toolchain in nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    oxalica = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk.url = "github:nix-community/naersk";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    oxalica,
    naersk,
    ...
  }: let
    overlay = import ./overlay.nix {
      inherit oxalica;
    };
  in
    {
      # Add our custom cache as recommended (it takes 25 minutes to build dojo)
      nixConfig.extra-substituters = "https://cache.valentin.red/cairo-nix";
      nixConfig.extra-trusted-public-keys = "cairo-nix:v8i37tyBwVBi/YKjomvylfaAUyk3GwvLhMaETHhxSCM=";

      overlays = {
        default = overlay;
      };

      templates = {
        default = {
          path = ./templates/simple;
          description = "A basic project using cairo-nix";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      patchedPkgs =
        (import nixpkgs {
          inherit system;
        })
        .applyPatches
        {
          name = "nixpkgs-unstable-patched";
          src = nixpkgs;
          patches = [
            ./patches/nixpkgs.patch
          ];
        };

      pkgs = import patchedPkgs {
        inherit system;
        overlays = [
          overlay
          oxalica.overlays.default
        ];
      };

      inherit (pkgs) lib;

      dojo-git = import ./packages/dojo.nix {inherit pkgs lib;};
      dojo-download = import ./packages/dojo-download.nix {inherit pkgs lib;};
    in {
      formatter = pkgs.nixpkgs-fmt;

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          cargo
          cairo-bin.stable.cairo
          cairo-bin.stable.scarb
        ];
      };

      legacyPackages = {
        inherit (dojo-git) dojo;
        cairo = pkgs.cairo-bin;
      };

      packages =
        dojo-git.flattened
        // {
          default = pkgs.cairo-bin.stable.scarb;
          inherit (pkgs.cairo-bin.stable) cairo scarb;

          dojo = dojo-download.dojo;

          cairo-beta = pkgs.cairo-bin.beta.cairo;
          scarb-beta = pkgs.cairo-bin.beta.scarb;

          slot = import ./packages/slot-download.nix {inherit pkgs lib;};
          starkli = import ./packages/starkli.nix {inherit pkgs lib;};
        };
    });
}
