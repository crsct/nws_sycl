# Readme

this is a sycl demo. it implements the needlemanwunsch algorithm that aligns two arbitrary strings with each other.

## Executing

You'll need a working sycl implementation an opensource implementation is [AdaptiveCpp](https://github.com/AdaptiveCpp/AdaptiveCpp?tab=readme-ov-file#installing-and-using-adaptivecpp).

if you are comfortable with installing another package manager or are already using [NixOS/Nix](https://www.nixos.org) you can clone the repository and simply run `nix develope` to have a working shell.

I have setup the makefile for adaptivecpp's compiler, if you use something else, you might want to adapt the call or add it to the makefile.

The compiled binary is located in build/output and takes two arguments seperated by space.
