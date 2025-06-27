{
  pkgs,
  inputs,
  ...
}: let
  crane = inputs.crane;
  craneLib = crane.mkLib pkgs;

  pname = "scarb";
  version = "2.11.4";

  cairo = {
    rev = "2.11.4";
    hash = "sha256-3EiNjKT5kyTLoxiAW4UseHdW0Ox/93dlnh8F+xfvwvo=";
  };

  src = pkgs.fetchFromGitHub {
    owner = "software-mansion";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Xq5tIGJV9gBKhBZ0ggCdGOYGc5/3MaEUQL+ToLJdGC4=";
  };

  fetchCairo = {
    rev,
    hash,
  }:
    pkgs.fetchurl {
      name = "cairo-archive-${rev}";
      url = "https://github.com/starkware-libs/cairo/archive/v${rev}.zip";
      sha256 = hash;
      meta = {
        version = rev;
      };
    };
in
  craneLib.buildPackage {
    inherit src pname version;

    nativeBuildInputs = with pkgs; [
      pkg-config
      openssl
    ];

    CAIRO_ARCHIVE = fetchCairo {
      rev = cairo.rev;
      hash = cairo.hash;
    };
  }
