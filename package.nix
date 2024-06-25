{ stdenv
, fetchFromGitHub
, flex
, bison
, boost
, gsl
,
}:
stdenv.mkDerivation {
  name = "gapc";
  version = "2023-07-05";

  src = fetchFromGitHub {
    owner = "crsct";
    repo = "nws_sycl";
    sha256 = "";
  };

  nativeBuildInputs = [
    nixpkgs-fmt
    opensycl
    gnumake
    python3
    clang-tools
    clang
    gdb

    llvmPackages_latest.llvm
    llvmPackages_latest.libcxxClang
    llvmPackages_latest.libcxxStdenv
    llvmPackages_latest.bintools
    llvmPackages_latest.openmp

    lld
    pkg-config
  ];

  buildPhase = ''
    acpp -g -O3 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wcast-align -Wconversion -Wsign-conversion -Wnull-dereference src/nws.cc -o nws_sycl
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp nws_sycl $out/bin
  '';
}
