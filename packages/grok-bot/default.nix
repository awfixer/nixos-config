{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
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
  libgbm,
  libGL,
  libnotify,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxtst,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemd,
  util-linux,
  vulkan-loader,
  wayland,
  xdg-utils,
}:

let
  pname = "grok-bot";
  version = "0.44.0";
  # Current target of
  # https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-fb0a830618be0c54
  commit = "12dcfa973ef51585fd1b35df6839fc9d1d7fd6aa";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://downloads.cursor.com/grokbot/stable/${commit}/linux/x64/grok-bot_${version}_amd64.deb";
    hash = "sha256-3e0YstPUSxwy1rn2NEbSsnvKaLPeeiqgKM55VulpQWQ=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
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
    libgbm
    libnotify
    libsecret
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxtst
    nspr
    nss
    pango
    (lib.getLib util-linux)
    stdenv.cc.cc
  ];

  runtimeDependencies = [
    libGL
    vulkan-loader
    wayland
    pipewire
    systemd
    pciutils
  ];

  appendRunpaths = [
    "${libGL}/lib"
    "${lib.getLib vulkan-loader}/lib"
    "${wayland}/lib"
    "${pipewire}/lib"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontWrapGApps = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${pname}
    cp -a "opt/Grok Bot/." $out/share/${pname}/
    chmod -R u+w $out/share/${pname}

    # chrome-sandbox cannot be setuid in the Nix store.
    rm -f $out/share/${pname}/chrome-sandbox

    if [ -e $out/share/${pname}/libvulkan.so.1 ]; then
      rm -f $out/share/${pname}/libvulkan.so.1
      ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $out/share/${pname}/libvulkan.so.1
    fi

    install -Dm644 usr/share/applications/grok-bot.desktop \
      $out/share/applications/grok-bot.desktop
    cp -a usr/share/icons $out/share/

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper $out/share/${pname}/grok-bot $out/bin/grok-bot \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "$out/share/${pname}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils pciutils ]}" \
      --add-flags "--no-sandbox"
  '';

  meta = {
    description = "Grok Bot desktop agent";
    homepage = "https://cursor.com";
    downloadPage = "https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-fb0a830618be0c54";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
