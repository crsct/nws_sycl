{
  description = "Needleman Wunsch Sycl implementation";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
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
        pkgs = (import nixpkgs {
          system = system;
          config = {
            # cudaPackages = pkgs.cudaPackages_11_5;
            cudaForwardCompat = true;
            cudaCapabilities = [ "7.5" ];
            cudaSupport = true;
            allowUnfree = true; # Enable unfree software
          };
        });
      in
      {
        # overlay = overlay;
        devShells.default = import ./shell.nix { inherit pkgs; };
        packages = {
          default = pkgs.callPackage ./package.nix { inherit pkgs; };
          sycl = pkgs.callPackage ./opensycl.nix { cudaPackages = cudaPackages_12_1; inherit pkgs; };
        };
      });
}
