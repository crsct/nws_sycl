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
  ];
}
