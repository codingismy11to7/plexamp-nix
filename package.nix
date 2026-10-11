{
  lib,
  appimageTools,
  fetchurl,
  runCommand,
}:
let
  pname = "plexamp";
  version = "4.50.19";

  src = fetchurl {
    url = "https://plexamp.plex.tv/desktop/Plexamp-${version}-x86_64.AppImage";
    name = "Plexamp-${version}-x86_64.AppImage";
    hash = "sha256-UgMaHzGb4oR2Wpnbp0yyp/YkSRFb0hnKW5pMFCMou6o=";
  };

  # The AppImage's linuxdeploy GTK hook unconditionally forces GDK_BACKEND=x11
  # (tauri-apps/tauri#8541). Under XWayland, GTK3 truncates a fractional
  # GDK_SCALE (e.g. 1.5) to 1 and the UI renders too small, so default to
  # native Wayland instead while still honoring an explicit GDK_BACKEND.
  # If the window ever renders blank/black on NVIDIA, try
  # WEBKIT_DISABLE_DMABUF_RENDERER=1 (not needed on 4.50.19 in testing).
  appimageContents = runCommand "${pname}-${version}-patched" { } ''
    cp -r ${appimageTools.extractType2 { inherit pname version src; }} $out
    chmod -R u+w $out
    substituteInPlace $out/apprun-hooks/linuxdeploy-plugin-gtk.sh \
      --replace-fail 'export GDK_BACKEND=x11' ': "''${GDK_BACKEND:=wayland}"; export GDK_BACKEND #'
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

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
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
