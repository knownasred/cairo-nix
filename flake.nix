{
  description = "Cairo toolchain in nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
      };

      packages =
        dojo-git.flattened
        // {
          default = pkgs.cairo-bin.stable.scarb;
          inherit (pkgs.cairo-bin.stable) cairo scarb;

          cairo-beta = pkgs.cairo-bin.beta.cairo;
          scarb-beta = pkgs.cairo-bin.beta.scarb;

          sozo-git = dojo-git.dojo."1.0.8".sozo;

          starkli = import ./packages/starkli.nix {inherit pkgs lib;};
        };
    });
}
