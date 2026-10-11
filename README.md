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

Plexamp's Tauri updater feed is `https://plexamp.plex.tv/desktop/tauri-update.json`
(the old electron-updater `latest-linux.yml` is stale). `scripts/update.sh`
reads it, verifies each AppImage against the feed's minisign signature using the
public key embedded in the Plexamp binary (`scripts/plexamp.pub`), and writes the
new version and hashes to `sources.json`:

```sh
nix shell nixpkgs#jq nixpkgs#minisign -c scripts/update.sh
```

The `Update Plexamp` workflow runs it every 6 hours. A new release is committed to
an `update/plexamp-<version>` branch, built on x86_64 and aarch64 runners, and
fast-forwarded onto `main` only if both builds pass.

## Notes

The bundled GTK hook forces `GDK_BACKEND=x11`; this package patches it to
default to `wayland` (fractional `GDK_SCALE` is truncated under XWayland, so the
UI rendered too small). Set `GDK_BACKEND=x11` to override.

If the window renders blank/black on NVIDIA, wrap with
`WEBKIT_DISABLE_DMABUF_RENDERER=1` (not needed as of 4.50.19).
