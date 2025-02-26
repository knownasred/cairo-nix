{
  description = "Cairo toolchain in nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    oxalica = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane.url = "github:ipetkov/crane";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };

    naersk.url = "github:nix-community/naersk";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    oxalica,
    crane,
    fenix,
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
      dojo-crane = import ./packages/dojo-crane.nix {inherit pkgs lib crane fenix;};
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

          cairo-beta = pkgs.cairo-bin.beta.cairo;
          scarb-beta = pkgs.cairo-bin.beta.scarb;

          dojo-test = dojo-crane {
            "version" = "1.2.1";
            "rustVersion" = "1.81.0";
            "srcHash" = "sha256-AgKK8fKWN1yepb2SMiAT/d2F8/jygl2UTau2iLraBBU=";
            "depsHash" = "sha256-CeiQm1XVoDJLe7UIYhvoQ5ieQWy0pwkKub78FK5Z/7E=";
            "cairoVersion" = "2.9.2";
            "cairoHash" = "sha256-mxTklhzHeZmF4AYS9IHySoaBwitqjjUnybfjyt/gEuI=";
            "patches" = true;
          };

          slot = import ./packages/slot-download.nix {inherit pkgs lib;};
          starkli = import ./packages/starkli.nix {inherit pkgs lib;};
        };
    });
}
