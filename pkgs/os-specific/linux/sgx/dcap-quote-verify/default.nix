{ lib, stdenv,
  systemd,
  sgx-dcap,
}:

let inherit (lib) optional; in

let self = stdenv.mkDerivation rec {
  inherit (sgx-dcap) version;
  pname = "libsgx-dcap-quote-verify";

  outputs = [ "dev" "out" ];

  nativeBuildInputs = [ 
        systemd
        sgx-dcap
  ];

  unpackPhase = ''
	cp -avr ${sgx-dcap}/${pname} .	
        chmod -R u+w .
  '';

  buildPhase = ''
	mkdir out
        DESTDIR=$(pwd)/out
	echo $(pwd) $PWD
        make DESTDIR=$DESTDIR -C ${pname}/output install
  '';

  # sigh... Intel!
  installPhase = ''
        runHook preInstall

	mkdir $out
	cp -avr out/${pname}*/usr/. $out/

        runHook postInstall
  '';

  doCheck = false;

  meta = with lib; {
    description = "Intel(R) Software Guard Extensions Data Center Attestation Primitives";
    homepage = "https://github.com/intel/SGXDataCenterAttestationPrimitives";
    platforms = [ "x86_64-linux" ];
    license = with licenses; [ bsd3 ];
  };
};
  in self
