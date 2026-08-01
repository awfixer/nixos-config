{
  lib,
  stdenv,
  fetchzip,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable,
  copyDesktopItems,
  makeDesktopItem,
  gtk3,
  adwaita-icon-theme,
  alsa-lib,
  curl,
  dbus-glib,
  libXtst,
  ffmpeg_7,
  libva,
  libGL,
  pciutils,
  pipewire,
}:

let
  pname = "zen-browser";
  version = "1.21.9b";
  binaryName = "zen";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchzip {
    url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
    hash = "sha256-g8rT4h94Pilnwx6gqeI/XwMf634JrFYtbdR8XNG1mbw=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libXtst
    ffmpeg_7
  ];

  runtimeDependencies = [
    curl
    libva.out
    pciutils
    libGL
  ];

  appendRunpaths = [
    "${libGL}/lib"
    "${pipewire}/lib"
  ];

  patchelfFlags = [ "--no-clobber-old-sections" ];

  desktopItems = [
    (makeDesktopItem {
      name = binaryName;
      desktopName = "Zen Browser";
      exec = "${binaryName} %u";
      icon = "zen-browser";
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "application/x-xpinstall"
        "application/pdf"
        "application/json"
      ];
      startupWMClass = binaryName;
      startupNotify = true;
      terminal = false;
      keywords = [ "Internet" "WWW" "Browser" "Web" "Explorer" ];
    })
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ ffmpeg_7 ]}"
      --add-flags "--name=''${MOZ_APP_LAUNCHER:-${binaryName}}"
      --add-flags "--class=''${MOZ_APP_LAUNCHER:-${binaryName}}"
    )
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/${pname}"
    cp -r $src/* "$out/lib/${pname}/"

    mkdir -p "$out/bin"
    ln -s "$out/lib/${pname}/${binaryName}" "$out/bin/${binaryName}"

    install -D $src/browser/chrome/icons/default/default16.png $out/share/icons/hicolor/16x16/apps/zen-browser.png
    install -D $src/browser/chrome/icons/default/default32.png $out/share/icons/hicolor/32x32/apps/zen-browser.png
    install -D $src/browser/chrome/icons/default/default48.png $out/share/icons/hicolor/48x48/apps/zen-browser.png
    install -D $src/browser/chrome/icons/default/default64.png $out/share/icons/hicolor/64x64/apps/zen-browser.png
    install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen-browser.png

    runHook postInstall
  '';

  meta = {
    description = "Experience tranquillity while browsing the web without people tracking you";
    homepage = "https://zen-browser.app";
    changelog = "https://github.com/zen-browser/desktop/releases";
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = binaryName;
  };
}