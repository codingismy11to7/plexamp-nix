{
  lib,
  appimageTools,
  fetchurl,
  runCommand,
  stdenv,
}:
let
  pname = "plexamp";

  # Maintained by scripts/update.sh from Plexamp's Tauri update feed.
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;

  inherit (stdenv.hostPlatform) system;
  arch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "aarch64";
    }
    .${system} or (throw "plexamp: unsupported system ${system}");

  src = fetchurl {
    url = "https://plexamp.plex.tv/desktop/Plexamp-${version}-${arch}.AppImage";
    name = "Plexamp-${version}-${arch}.AppImage";
    hash = sources.hashes.${system};
  };

  # The AppImage's linuxdeploy GTK hook unconditionally forces GDK_BACKEND=x11
  # (tauri-apps/tauri#8541). Under XWayland, GTK3 truncates a fractional
  # GDK_SCALE (e.g. 1.5) to 1 and the UI renders too small, so default to
  # native Wayland instead while still honoring an explicit GDK_BACKEND.
  # If the window ever renders blank/black on NVIDIA, try
  # WEBKIT_DISABLE_DMABUF_RENDERER=1 (not needed on 4.50.19 in testing).
  #
  # The AppImage also bundles Ubuntu's libwayland-*, which shadows the host's.
  # The host mesa's libEGL_mesa needs a newer libwayland-client
  # (wl_fixes_interface), fails to load, and WebKit aborts with "Could not
  # create default EGL display: EGL_BAD_PARAMETER" on Intel/AMD. NVIDIA's EGL
  # doesn't need it, so it only shows up on mesa. Drop them and use nixpkgs'.
  appimageContents = runCommand "${pname}-${version}-patched" { } ''
    cp -r ${appimageTools.extract { inherit pname version src; }} $out
    chmod -R u+w $out
    substituteInPlace $out/apprun-hooks/linuxdeploy-plugin-gtk.sh \
      --replace-fail 'export GDK_BACKEND=x11' ': "''${GDK_BACKEND:=wayland}"; export GDK_BACKEND #'
    rm $out/usr/lib/libwayland-*.so*
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraPkgs = pkgs: [ pkgs.wayland ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/Plexamp.desktop $out/share/applications/plexamp.desktop
    substituteInPlace $out/share/applications/plexamp.desktop \
      --replace-fail 'Exec=Plexamp' 'Exec=${pname} %U' \
      --replace-fail 'StartupWMClass=tv.plex.plexamp' 'StartupWMClass=Plexamp'
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Beautiful Plex music player for audiophiles, curators, and hipsters (Tauri build)";
    homepage = "https://plexamp.com/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames sources.hashes;
    mainProgram = pname;
  };
}
