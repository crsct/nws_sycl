{ pkgs ? import <nixpkgs> }:

with pkgs;
mkShell {
  buildInputs = [
    (callPackage ./opensycl.nix { })
    gnumake
    gdb

    lld
    cudaPackages.cudatoolkit
    linuxPackages.nvidia_x11
    opencl-headers
    pkg-config
  ];

  shellHook = ''
    # Ensure CUDA and NVIDIA tools are available
    export CUDA_HOME=${cudaPackages.cudatoolkit}
    export NVIDIA_VISIBLE_DEVICES=all
    export NVIDIA_DRIVER_CAPABILITIES=compute,utility
    export PATH=${pkgs.linuxPackages.nvidia_x11.bin}/bin:$PATH
    export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH
    export LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:$LIBRARY_PATH
    export CC=${pkgs.gcc11}
  '';

  # Ensure the NVIDIA driver kernel module is loaded
  preBuild = ''
    modprobe nvidia
  '';
}
