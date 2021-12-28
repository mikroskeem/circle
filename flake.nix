{
  description = "Circle compiler";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "x86_64-linux"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      rec {
        packages.circle-unwrapped = pkgs.callPackage ./circle.nix { };
        packages.circle = pkgs.wrapCCWith {
          cc = packages.circle-unwrapped;
        };
        defaultPackage = packages.circle;
      });
}
