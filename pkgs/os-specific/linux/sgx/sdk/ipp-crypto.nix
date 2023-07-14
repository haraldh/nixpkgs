{ lib
, gcc11Stdenv
, fetchFromGitHub
, cmake
, nasm
, ninja
, openssl
, python3
, extraCmakeFlags ? [ ]
}:

gcc11Stdenv.mkDerivation rec {
  pname = "ipp-crypto";
  version = "2021.3";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipp-crypto";
    rev = "ippcp_${version}";
    hash = "sha256-QEJXvQ//zhQqibFxXwPMdS1MHewgyb24LRmkycVSGrM=";
  };

  # Fix typo: https://github.com/intel/ipp-crypto/pull/33
  postPatch = ''
    substituteInPlace sources/cmake/ippcp-gen-config.cmake \
      --replace 'ippcpo-config.cmake' 'ippcp-config.cmake'
    substituteInPlace \
sources/cmake/linux/Clang9.0.0.cmake \
sources/cmake/linux/GNU8.2.0.cmake \
sources/cmake/linux/Intel19.0.0.cmake \
sources/cmake/macosx/AppleClang11.0.0.cmake \
sources/cmake/macosx/Intel19.0.0.cmake \
sources/ippcp/crypto_mb/src/cmake/linux/Clang.cmake \
sources/ippcp/crypto_mb/src/cmake/linux/GNU.cmake \
sources/ippcp/crypto_mb/src/cmake/linux/Intel.cmake \
sources/ippcp/crypto_mb/src/cmake/macosx/AppleClang.cmake \
sources/ippcp/crypto_mb/src/cmake/macosx/Intel.cmake \
      --replace 'Werror"' 'Werror -Wno-error=deprecated-declarations"'
  '';

  preConfigure = ''
    export CFLAGS="$CFLAGS -Wno-error=deprecated-declarations"
  '';

  cmakeFlags = [ "-DARCH=intel64" ] ++ extraCmakeFlags;

  nativeBuildInputs = [
    cmake
    nasm
    ninja
    openssl
    python3
  ];
}
