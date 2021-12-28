let
  pkgs = import <nixpkgs> { };
  circle-unwrapped = pkgs.callPackage ./circle.nix { };
  circleStdenv = pkgs.overrideCC pkgs.stdenv { cc = circle-unwrapped; };

  sanityFile = ./sanity.cxx;
in
pkgs.runCommandWith { stdenv = circleStdenv; name = "circle-test"; runLocal = true; } ''
  cc ./sanity.cxx
''
