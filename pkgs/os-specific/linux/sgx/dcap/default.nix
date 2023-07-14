{ lib, stdenv, fetchFromGitHub,
  fetchurl,
  boost,
  python3,
  openssl,
  which,
  wget,
  curl,
  zip,
  sgx-sdk,
  sgx-ssl,
}:

let inherit (lib) optional; in

let self = stdenv.mkDerivation rec {
  pname = "sgx-dcap";
  version = "1.16";

  postUnpack =
    let
      dcap = rec {
        version = "1.16";
        filename = "prebuilt_dcap_${version}.tar.gz";
        prebuilt = fetchurl {
          url = "https://download.01.org/intel-sgx/sgx-dcap/${version}/linux/${filename}";
          hash = "sha256-LBOglLkn/IX6J4bOUJl9ipKjgENjpy5n8Zhc60CTLFA=";
        };
      };
    in
    ''
      # Make sure we use the correct version of prebuilt DCAP
      grep -q 'ae_file_name=${dcap.filename}' "$sourceRoot/QuoteGeneration/download_prebuilt.sh" \
        || (echo "Could not find expected prebuilt DCAP ${dcap.filename} in dcap source" >&2 && exit 1)

      tar -zxf ${dcap.prebuilt} -C $sourceRoot/QuoteGeneration/
    '';

  src = fetchFromGitHub {
      owner = "intel";
      repo = "SGXDataCenterAttestationPrimitives";
      rev = "71557c7d1d869b6bd6f95566c051cbd098549509";
      hash = "sha256-8MkTeuEvnUDPJlYfw62803WGIb4qZpLHWtIVd06NAJU=";
  };

  outputs = [ "out" ];

  patchPhase = ''
    patchShebangs --build $(find . -name '*.sh')
  '';

  preBuild = ''
    makeFlagsArray+=(SGX_SDK="${sgx-sdk}" SGXSSL_PACKAGE_PATH="${sgx-ssl}")
  '';

  # sigh... Intel!
  enableParallelBuilding = false;

  # sigh... Intel!
  installPhase = ''
        runHook preInstall

	# sigh... Intel!
    	mkdir -p QuoteGeneration/pccs/lib/
	cp tools/PCKCertSelection/out/libPCKCertSelection.so QuoteGeneration/pccs/lib/
	mkdir $out
	for i in \
./QuoteGeneration/installer/linux/common/libsgx-ae-id-enclave \
./QuoteGeneration/installer/linux/common/libsgx-ae-qe3 \
./QuoteGeneration/installer/linux/common/libsgx-ae-qve \
./QuoteGeneration/installer/linux/common/libsgx-ae-tdqe \
./QuoteGeneration/installer/linux/common/libsgx-dcap-default-qpl \
./QuoteGeneration/installer/linux/common/libsgx-dcap-ql \
./QuoteGeneration/installer/linux/common/libsgx-dcap-quote-verify \
./QuoteGeneration/installer/linux/common/libsgx-pce-logic \
./QuoteGeneration/installer/linux/common/libsgx-qe3-logic \
./QuoteGeneration/installer/linux/common/libsgx-tdx-logic \
./QuoteGeneration/installer/linux/common/libtdx-attest \
./QuoteGeneration/installer/linux/common/sgx-dcap-pccs \
./QuoteGeneration/installer/linux/common/tdx-qgs \
./tools/PCKRetrievalTool/installer/common/sgx-pck-id-retrieval-tool \
./tools/SGXPlatformRegistration/package/installer/common/libsgx-ra-network \
./tools/SGXPlatformRegistration/package/installer/common/libsgx-ra-uefi \
./tools/SGXPlatformRegistration/package/installer/common/sgx-ra-service \
; do
        echo "Processing $i"
	"$i"/createTarball.sh
	cp -avr "$i" $out/
done

        runHook postInstall
  '';

  nativeBuildInputs = [ 
	openssl
        python3
        boost
        curl
        sgx-sdk
        which
        wget
        zip
  ];

  doCheck = false;

  dontDisableStatic = false;


  meta = with lib; {
    description = "Intel(R) Software Guard Extensions Data Center Attestation Primitives";
    homepage = "https://github.com/intel/SGXDataCenterAttestationPrimitives";
    platforms = [ "x86_64-linux" ];
    license = with licenses; [ bsd3 ];
  };
};
  in self
