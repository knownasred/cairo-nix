{
  description = "Cairo toolchain in nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    oxalica = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, oxalica, ... }:
    let
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
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            cargo
            cairo-bin.stable.cairo
            cairo-bin.stable.scarb
          ];
        };

        packages = {
          default = pkgs.cairo-bin.stable.scarb;
          cairo = pkgs.cairo-bin.stable.cairo;
          scarb = pkgs.cairo-bin.stable.scarb;
          cairo-beta = pkgs.cairo-bin.beta.cairo;
          scarb-beta = pkgs.cairo-bin.beta.scarb;
        };
      });
}
