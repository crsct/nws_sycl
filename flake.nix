{
  description = "Bellman's GAP compiler";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    sycl.url = "github:r-ryantm/nixpkgs/auto-update/opensycl";
  };

  outputs =
    { self
    , systems
    , nixpkgs
    , flake-utils
    , sycl
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        overlay = final: prev: {
          inherit (sycl.legacyPackages.${prev.system})
            opensycl;
        };
        pkgs = (nixpkgs.legacyPackages.${system}.extend overlay);

      in
      {
        # overlay = overlay;
        devShells.default = import ./shell.nix { inherit pkgs; };
        packages.default = pkgs.callPackage ./package.nix { };
      });
}
