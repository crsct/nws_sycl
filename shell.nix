{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = [
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


    git
    gitRepo
    gnupg
    autoconf
    curl
    procps
    gnumake
    util-linux
    m4
    gperf
    unzip
    cudatoolkit
    libGLU
    libGL
    freeglut
    zlib
    ncurses5
    stdenv.cc
    binutils
  ];

  shellHook = ''
    export CUDA_PATH=${pkgs.cudatoolkit}
    # export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
    # export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    export EXTRA_CCFLAGS="-I/usr/include"
  '';
}
