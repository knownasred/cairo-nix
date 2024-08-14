{ lib
, pkgs
, naersk
, ...
}:
let
  name = "dojo";
  version = "0.7.3";
  src = pkgs.fetchFromGitHub {
    owner = "dojoengine";
    repo = "dojo";
    rev = "v${version}";
    hash = "sha256-Fh/e1zcJRLK74LBbC6kqAG009ARrjDbCXWFUZ97TsMo=";
  };

  naersk' = pkgs.callPackage naersk { };

  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable."1.76.0".minimal;
    rustc = pkgs.rust-bin.stable."1.76.0".minimal;
  };

  /*
    lockFile = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;

    outputHashes = {
      "account_sdk-0.1.0" = lib.fakeHash;
      "alloy-0.2.0" = lib.fakeHash;
      "alloy-consensus-0.2.0" = lib.fakeHash;
      "alloy-contract-0.2.0" = lib.fakeHash;
      "alloy-eips-0.2.0" = lib.fakeHash;
      "alloy-genesis-0.2.0" = lib.fakeHash;
      "alloy-json-abi-0.2.0" = lib.fakeHash;
      "alloy-json-rpc-0.2.0" = lib.fakeHash;
      "alloy-network-0.2.0" = lib.fakeHash;
      "alloy-node-bindings-0.2.0" = lib.fakeHash;
      "alloy-primitives-0.2.0" = lib.fakeHash;
      "alloy-provider-0.2.0" = lib.fakeHash;
      "alloy-rpc-client-0.2.0" = lib.fakeHash;
      "alloy-rpc-types-anvil-0.2.0" = lib.fakeHash;
      "alloy-rpc-types-eth-0.2.0" = lib.fakeHash;
      "alloy-serde-0.2.0" = lib.fakeHash;
      "alloy-signer-0.2.0" = lib.fakeHash;
      "alloy-signer-local-0.2.0" = lib.fakeHash;
      "alloy-transport-0.2.0" = lib.fakeHash;
      "alloy-transport-http-0.2.0" = lib.fakeHash;
      "blockifier-0.8.0-dev.2" = lib.fakeHash;
      "cainome-0.2.3" = lib.fakeHash;
      "cainome-cairo-serde-0.1.0" = lib.fakeHash;
      "cainome-parser-0.1.0" = lib.fakeHash;
      "cainome-rs-0.1.0" = lib.fakeHash;
      "cainome-rs-macro-0.1.0" = lib.fakeHash;
      "cairo-lang-macro-0.1.0" = lib.fakeHash;
      "cairo-proof-parser-0.3.0" = lib.fakeHash;
      "common-0.1.0" = lib.fakeHash;
      "create-output-dir-1.0.0" = lib.fakeHash;
      "hyper-reverse-proxy-0.5.2-dev" = lib.fakeHash;
      "ipfs-api-backend-hyper-0.6.0" = lib.fakeHash;
      "ipfs-api-prelude-0.6.0" = lib.fakeHash;
      "libp2p-0.54.0" = lib.fakeHash;
      "libp2p-allow-block-list-0.3.0" = lib.fakeHash;
    };
  */

in
{
  dojo-language-server = naersk'.buildPackage {
    root = "${src}";
    src = "${src}/bin/dojo-language-server";
  };

  katana = naersk'.buildPackage {
    root = "${src}";
    src = "${src}/bin/katana";
  };

  sozo = naersk'.buildPackage {
    root = "${src}";
    src = "${src}/bin/sozo";
  };

  torii = naersk'.buildPackage {
    root = "${src}";
    src = "${src}/bin/torii";
  };
}
