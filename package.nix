{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "plexamp";
  version = "4.50.19";

  src = fetchurl {
    url = "https://plexamp.plex.tv/desktop/Plexamp-${version}-x86_64.AppImage";
    name = "Plexamp-${version}-x86_64.AppImage";
    hash = "sha256-UgMaHzGb4oR2Wpnbp0yyp/YkSRFb0hnKW5pMFCMou6o=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # If the window ever renders blank/black on NVIDIA, add:
  #   --set WEBKIT_DISABLE_DMABUF_RENDERER 1
  # (not needed on 4.50.19 in testing)
  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/Plexamp.desktop $out/share/applications/plexamp.desktop
    substituteInPlace $out/share/applications/plexamp.desktop \
      --replace-fail 'Exec=Plexamp' 'Exec=${pname} %U'
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
