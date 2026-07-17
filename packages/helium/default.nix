{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  makeWrapper,
  wrapGAppsHook3,
  # Linked dynamic libraries (same class of deps as google-chrome).
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  libva,
  libGL,
  vulkan-loader,
  wayland,
  libpulseaudio,
  pciutils,
  addDriverRunpath,
}:

let
  pname = "helium";
  version = "0.14.5.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-x86_64.AppImage";
    hash = "sha256-JM4Tm4Le9Xcfq3fFMEu/DIK6817FEgBQ2rSwY093F04=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };

  rpath = lib.makeLibraryPath [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libgbm
    nspr
    nss
    pango
    pipewire
    systemd
    libva
    libGL
    vulkan-loader
    wayland
    libpulseaudio
    pciutils
  ];
in
stdenv.mkDerivation rec {
  inherit pname version;

  src = appimageContents;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
  ];

  # Avoid wrapping the many helper binaries; we only wrap the launcher.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share}
    cp -a opt/helium $out/share/helium
    cp -a usr/share/* $out/share/ 2>/dev/null || true

    # Desktop entry from the AppImage (already has Exec=helium).
    install -Dm644 ${appimageContents}/helium.desktop $out/share/applications/helium.desktop

    # Icons
    if [ -f ${appimageContents}/helium.png ]; then
      install -Dm644 ${appimageContents}/helium.png \
        $out/share/icons/hicolor/256x256/apps/helium.png
    fi
    if [ -d ${appimageContents}/usr/share/icons ]; then
      cp -a ${appimageContents}/usr/share/icons $out/share/
    fi

    # Interpreter + RPATH so we do NOT need bubblewrap/FHS.
    # bwrap sets no_new_privs which strips setgid from 1Password-BrowserSupport
    # ("process detected it was running without libc's security, aborting").
    for elf in $out/share/helium/{helium,chrome_crashpad_handler,chrome,chromedriver,helium_crashpad_handler}; do
      if [ -f "$elf" ] && [ -x "$elf" ]; then
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$elf" || true
        patchelf --set-rpath "$out/share/helium:${rpath}" "$elf" || true
      fi
    done
    for so in $out/share/helium/lib*.so*; do
      if [ -f "$so" ]; then
        patchelf --set-rpath "$out/share/helium:${rpath}" "$so" || true
      fi
    done

    # Replace bundled vulkan loader with nixpkgs one when present.
    if [ -e $out/share/helium/libvulkan.so.1 ]; then
      rm -f $out/share/helium/libvulkan.so.1
      ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $out/share/helium/libvulkan.so.1
    fi

    makeWrapper $out/share/helium/helium $out/bin/helium \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "$out/share/helium:${rpath}" \
      --prefix PATH : "${lib.makeBinPath [ pciutils ]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    runHook postInstall
  '';

  meta = {
    description = "Private, fast, and honest web browser based on Chromium";
    homepage = "https://github.com/imputnet/helium-chromium";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${version}";
    license = lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
