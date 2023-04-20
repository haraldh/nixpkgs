{ stdenv
, fetchFromGitHub
, fetchpatch
, fetchurl
, lib
, openssl
, perl
, sgx-sdk
, which
, debug ? false
}:
let
  sgxVersion = sgx-sdk.versionTag;
  opensslVersion = "1.1.1t";
in
stdenv.mkDerivation rec {
  pname = "sgx-ssl" + lib.optionalString debug "-debug";
  version = "${sgxVersion}_${opensslVersion}";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "intel-sgx-ssl";
    rev = "lin_${sgxVersion}_${opensslVersion}";
    hash = "sha256-EpEtsYBa0I5oF0QwdKwjCRV70t1kujzkuT8kjWDpSn0=";
  };

  postUnpack =
    let
      opensslSourceArchive = fetchurl {
        url = "https://www.openssl.org/source/openssl-${opensslVersion}.tar.gz";
        hash = "sha256-je6bJL2x3L8MPR6bAvuPa/IhZegH9Fret8lndTaFnTs=";
      };
    in
    ''
      ln -s ${opensslSourceArchive} $sourceRoot/openssl_source/openssl-${opensslVersion}.tar.gz
    '';

  postPatch = ''
    patchShebangs Linux/build_openssl.sh

    # Run the test in the `installCheckPhase`, not the `buildPhase`
    substituteInPlace Linux/sgx/Makefile \
      --replace '$(MAKE) -C $(TEST_DIR) all' \
                'bash -c "true"'
  '';

  enableParallelBuilding = true;

  nativeBuildInputs = [
    openssl
    perl
    sgx-sdk
    stdenv.cc.libc
    which
  ];

  makeFlags = [
    "-C Linux"
  ] ++ lib.optionals debug [
    "DEBUG=1"
  ];

  installFlags = [
    "DESTDIR=$(out)"
  ];

  # Build the test app
  #
  # Running the test app is currently only supported on Intel CPUs
  # and will fail on non-Intel CPUs even in SGX simulation mode.
  # Therefore, we only build the test app without running it until
  # upstream resolves the issue: https://github.com/intel/intel-sgx-ssl/issues/113
  doInstallCheck = true;
  installCheckTarget = "all";
  installCheckFlags = [
    "SGX_MODE=SIM"
    "-C sgx/test_app"
    "-j 1" # Makefile doesn't support multiple jobs
  ];
  preInstallCheck = ''
    # Expects the enclave file in the current working dir
    ln -s sgx/test_app/TestEnclave.signed.so .
  '';

  meta = with lib; {
    description = "Cryptographic library for Intel SGX enclave applications based on OpenSSL";
    homepage = "https://github.com/intel/intel-sgx-ssl";
    maintainers = with maintainers; [ trundle veehaitch ];
    platforms = [ "x86_64-linux" ];
    license = with licenses; [ bsd3 openssl ];
  };
}
