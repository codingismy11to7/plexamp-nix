{
  description = "Plexamp (Tauri build) packaged for Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );
    in
    {
      packages = forAllSystems (pkgs: {
        plexamp = pkgs.callPackage ./package.nix { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.plexamp;
      });

      overlays.default = final: _prev: {
        plexamp = final.callPackage ./package.nix { };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
