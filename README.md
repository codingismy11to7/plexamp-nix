# plexamp-nix

Nix flake for the Tauri-based [Plexamp](https://plexamp.com/) desktop app (4.50.x),
wrapped from the upstream AppImage with `appimageTools.wrapType2`. nixpkgs still
ships the old Electron build (4.13.2), which crashes on NVIDIA + Wayland.

```nix
inputs.plexamp = {
  url = "github:codingismy11to7/plexamp-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
# then: inputs.plexamp.packages.x86_64-linux.plexamp  (or overlays.default)
```

Unfree; consumers using the overlay need `allowUnfree`.

## Updating

The electron-updater feed (`latest-linux.yml`) is stale, so find the version
elsewhere (e.g. the AUR `plexamp-beta-appimage` package), then bump `version` in
`package.nix` and refresh the hash:

```sh
nix store prefetch-file https://plexamp.plex.tv/desktop/Plexamp-<version>-x86_64.AppImage
```

The bundled GTK hook forces `GDK_BACKEND=x11`; this package patches it to
default to `wayland` (fractional `GDK_SCALE` is truncated under XWayland, so the
UI rendered too small). Set `GDK_BACKEND=x11` to override.

If the window renders blank/black on NVIDIA, wrap with
`WEBKIT_DISABLE_DMABUF_RENDERER=1` (not needed as of 4.50.19).
