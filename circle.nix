{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, zlib
, elfutils
, libuuid
, runtimeShell
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
  ];

  dontAutoPatchelf = true;
  dontStrip = true;
  dontConfigure = true;

  prePatch = ''
    autoPatchelf circle
  '';

  buildPhase = ''
    runHook preBuild

    cp ${./redirect.c} redirect.c
    cc -DNDEBUG -D_LD='"ld"' -D_LDSO='"${stdenv.cc.libc_dev.out}/lib/ld-linux-x86-64.so.2"' -shared -fPIC -ldl -o redirect.so redirect.c

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D -m 755 redirect.so $out/lib/redirect.so
    install -D -m 755 circle $out/bin/.circle-real
    install -D -m 755 $wrappedCirclePath $out/bin/circle
    install -D -m 644 license.txt $out/share/$name/LICENSE

    runHook postInstall
  '';

  passAsFile = [ "wrappedCircle" ];

  wrappedCircle = ''
    #!${runtimeShell}

    circleFlags=(
      --isystem=${stdenv.cc.cc}/include/c++/${stdenv.cc.cc.version}
      --isystem=${stdenv.cc.cc}/include/c++/${stdenv.cc.cc.version}/${stdenv.buildPlatform.config}
      --isystem=${stdenv.cc.cc}/lib/gcc/${stdenv.buildPlatform.config}/${stdenv.cc.cc.version}/include
      --isystem=${stdenv.cc.cc}/lib/gcc/${stdenv.buildPlatform.config}/${stdenv.cc.cc.version}/include-fixed
      --isystem=${stdenv.cc.cc.libc_dev}/include
      -L ${stdenv.cc.cc}/lib/gcc/${stdenv.buildPlatform.config}/${stdenv.cc.cc.version}
      -L ${stdenv.cc.cc.lib.lib}/lib
      -L ${stdenv.cc.libc_dev.out}/lib
      #-Wl,--dynamic-linker=${stdenv.cc.libc_dev.out}/lib/ld-linux-x86-64.so.2
      #--gcc-toolchain=${stdenv.cc.cc.lib.out}
    )

    export LD_PRELOAD="${placeholder "out"}/lib/redirect.so"
    exec ${placeholder "out"}/bin/.circle-real ''${circleFlags[@]} "''${@}"
  '';

  checkPhase = ''
    # XXX: ugly
    install -m 755 $wrappedCirclePath wrappedCircle
    substituteInPlace wrappedCircle \
      --replace "${placeholder "out"}/bin/.circle-real" "./circle" \
      --replace "${placeholder "out"}/lib/redirect.so" "$(realpath ./redirect.so)"

    # Try compiling provided sanity check
    ./wrappedCircle --verbose sanity.cxx
    ./sanity

    # Test C++ features/libstdc++ linkage
    cp ${./tuple.cxx} tuple.cxx
    ./wrappedCircle --verbose tuple.cxx
    ./tuple
  '';

  doCheck = true;

  meta = with lib; {
    homepage = "https://www.circle-lang.org/";
    description = "Circle is a new C++20 compiler. It's written from scratch and designed for easy extension.";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
