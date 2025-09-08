{
  description = "Cairo toolchain in nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    oxalica = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    oxalica,
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
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          overlay
          oxalica.overlays.default
        ];
      };

      inherit (pkgs) lib;

      dojo-git = import ./packages/dojo.nix {inherit pkgs lib;};
      dojo-download = import ./packages/dojo-download.nix {inherit pkgs lib;};
      katana-download = import ./packages/katana-download.nix {inherit pkgs lib;};
      torii-download = import ./packages/torii-download.nix {inherit pkgs lib;};
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
          dojo = dojo-download.dojo;

          cairo-beta = pkgs.cairo-bin.beta.cairo;
          scarb-beta = pkgs.cairo-bin.beta.scarb;

          scarb = import ./packages/scarb-download.nix {inherit pkgs lib;};

          scarb-nightly = import ./packages/scarb-nightly.nix {inherit pkgs lib;};

          slot = import ./packages/slot-download.nix {inherit pkgs lib;};
          starkli = import ./packages/starkli.nix {inherit pkgs lib;};

          katana = katana-download;
          torii = torii-download;
        };
    });
}
