let
  f = builtins.getFlake (toString ./.);
  pkgs = import f.inputs.nixpkgs {
    config = {
      allowUnfree = true;
    };
  };
  circle = f.outputs.packages."x86_64-linux".circle;
  circleStdenv = pkgs.overrideCC pkgs.stdenv circle;

  sanityFile = ./tuple.cxx;
in
pkgs.runCommandWith { stdenv = circleStdenv; name = "circle-test"; runLocal = true; } ''
  circle ${sanityFile} -o $out
''
