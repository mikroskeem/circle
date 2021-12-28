{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, zlib
, elfutils
, libuuid
, binutils
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "circle";
  version = "145";

  src = fetchurl {
    url = "https://circle-lang.org/linux/build_${version}.tgz";
    sha256 = "sha256-RciKCJ5/je+iccGg8nylekhLDoazE50fxq+2wTx+Gxo=";
  };

  sourceRoot = ".";

  buildInputs = [ zlib elfutils libuuid stdenv.cc.cc.lib ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  dontAutoPatchelf = true;
  dontStrip = true;
  dontBuild = true;
  dontConfigure = true;

  patchPhase = ''
    autoPatchelf circle
  '';

  installPhase = ''
    install -D -m 755 circle $out/bin/circle
    install -D -m 644 license.txt $out/share/$name/LICENSE
  '';

  checkPhase = ''
    set -x

    circleFlags=(
      --isystem=${stdenv.cc.cc}/include/c++/${stdenv.cc.cc.version}
      --isystem=${stdenv.cc.cc}/include/c++/${stdenv.cc.cc.version}/${stdenv.buildPlatform.config}
      --isystem=${stdenv.cc.cc}/lib/gcc/${stdenv.buildPlatform.config}/${stdenv.cc.cc.version}/include
      --isystem=${stdenv.cc.cc}/lib/gcc/${stdenv.buildPlatform.config}/${stdenv.cc.cc.version}/include-fixed
      --isystem=${stdenv.cc.cc.libc_dev}/include
      -L ${stdenv.cc.cc}/lib/gcc/${stdenv.buildPlatform.config}/${stdenv.cc.cc.version}
      -L ${stdenv.cc.libc_dev.out}/lib
      #-Wl,--dynamic-linker=${stdenv.cc.libc_dev.out}/lib/ld-linux-x86-64.so.2
      #--gcc-toolchain=${stdenv.cc.cc.lib.out}
    )

    ./circle --verbose ''${circleFlags[@]} sanity.cxx
    ./sanity
  '';

  doCheck = true;

  meta = with lib; {
    homepage = "https://www.circle-lang.org/";
    description = "Circle is a new C++20 compiler. It's written from scratch and designed for easy extension.";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
