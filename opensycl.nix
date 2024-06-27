{ lib
, fetchFromGitHub
, llvmPackages_18
, lld_18
, python3
, cmake
, boost
, libxml2
, libffi
, makeWrapper
, config
, rocmPackages
, spirv-llvm-translator
, rocmSupport ? config.rocmSupport
, cudaPackages ? { }
, cudaSupport ? config.cudaSupport
, pkg-config
}:
let
  inherit (llvmPackages_18) stdenv;
in
stdenv.mkDerivation rec {
  pname = "OpenSYCL";
  version = "24.02.0";

  src = fetchFromGitHub {
    owner = "OpenSYCL";
    repo = "OpenSYCL";
    rev = "v${version}";
    sha256 = "sha256-9TBc5XZwz1is8D6PMfxs/MAttjXe6SLXGO5BnXIF2T0=";
  };

  nativeBuildInputs = [
    cmake
    makeWrapper
  ];

  buildInputs = [
    libxml2
    libffi
    boost
    pkg-config
    llvmPackages_18.openmp
    llvmPackages_18.libclang.dev
    llvmPackages_18.llvm
  ] ++ lib.optionals cudaSupport [
    spirv-llvm-translator
    cudaPackages.cudatoolkit
  ] ++ lib.optionals rocmSupport [
    rocmPackages.clr
    rocmPackages.rocm-runtime
  ];

  # opensycl makes use of clangs internal headers. Its cmake does not successfully discover them automatically on nixos, so we supply the path manually
  cmakeFlags = [
    "-DCLANG_INCLUDE_PATH=${llvmPackages_18.libclang.dev}/include"
    "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
    "-DLLVM_DIR=${llvmPackages_18.llvm}/lib/cmake/llvm"
  ];

  postFixup = ''
    wrapProgram $out/bin/syclcc-clang \
      --prefix PATH : ${lib.makeBinPath [ python3 lld_18 ]} \
      --add-flags "-L${llvmPackages_18.openmp}/lib" \
      --add-flags "-I${llvmPackages_18.openmp.dev}/include" \
  '' + lib.optionalString rocmSupport ''
    --add-flags "--rocm-device-lib-path=${rocmPackages.rocm-device-libs}/amdgcn/bitcode"
  '';

  meta = with lib; {
    homepage = "https://github.com/OpenSYCL/OpenSYCL";
    description = "Multi-backend implementation of SYCL for CPUs and GPUs";
    maintainers = with maintainers; [ yboettcher ];
    license = licenses.bsd2;
  };
}
