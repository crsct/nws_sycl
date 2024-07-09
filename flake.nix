{
  description = "Needleman Wunsch Sycl implementation";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , systems
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        overlays = final: prev: {
        };
        pkgs = (import nixpkgs {
          system = system;
          overlay = overlays;
          
          config = {
            cudaForwardCompat = true;
            cudaCapabilities = [ "7.5" ];
            cudaSupport = true;
            allowUnfree = true; # Enable unfree software
          };
        });
      in
      {
        devShells = {
            default = import ./shell.nix { inherit pkgs; };
            cuda_11_5 = import ./shell.nix { inherit pkgs; cudaPackages = pkgs.cudaPackages_11_5; };
        };
        packages = {
          default = pkgs.callPackage ./package.nix { inherit pkgs; };
          sycl = pkgs.callPackage ./opensycl.nix { inherit pkgs; };
        };
      });
}
