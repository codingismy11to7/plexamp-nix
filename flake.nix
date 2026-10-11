{
  description = "Plexamp (Tauri build) packaged for Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {
        plexamp = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.plexamp;
      };

      overlays.default = final: _prev: {
        plexamp = final.callPackage ./package.nix { };
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
