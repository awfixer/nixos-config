{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  # Runtime libraries required by the Qt GUI and helpers.
  acl,
  brotli,
  dbus,
  fontconfig,
  freetype,
  glib,
  harfbuzz,
  libGL,
  libcap_ng,
  libdrm,
  libglvnd,
  libnl,
  libx11,
  libxcb,
  libxcb-cursor,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-util,
  libxcb-wm,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrender,
  pcre2,
  wayland,
  zstd,
  systemd,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "windscribe";
  version = "2.24.12";

  src = fetchurl {
    url = "https://github.com/Windscribe/Desktop-App/releases/download/v${version}/windscribe_${version}_amd64.deb";
    hash = "sha256-mielHt6csk9f+8gw24kMOAcA8ygki5Q1G9SOmBHb8vQ=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    acl
    brotli
    dbus
    fontconfig
    freetype
    glib
    harfbuzz
    libGL
    libcap_ng
    libdrm
    libglvnd
    libnl
    libx11
    libxcb
    libxcb-cursor
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-util
    libxcb-wm
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrender
    pcre2
    wayland
    zstd
    systemd
    zlib
  ];

  runtimeDependencies = [
    libGL
    libglvnd
    wayland
    dbus
    (lib.getLib systemd)
  ];

  dontConfigure = true;
  dontBuild = true;

  # Preserve the /opt/windscribe layout the helper hardcodes at runtime.
  # modules/windscribe.nix symlinks /opt/windscribe → this path.
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share $out/lib/systemd/system

    cp -a opt/windscribe $out/opt/

    if [ -d usr/share/icons ]; then
      cp -a usr/share/icons $out/share/
    fi

    if [ -f usr/lib/systemd/system/windscribe-helper.service ]; then
      install -Dm644 usr/lib/systemd/system/windscribe-helper.service \
        $out/lib/systemd/system/windscribe-helper.service
      substituteInPlace $out/lib/systemd/system/windscribe-helper.service \
        --replace-fail "ExecStart=/opt/windscribe/helper" "ExecStart=$out/opt/windscribe/helper"
    fi

    # Prefer setgid security wrapper (services.windscribe) so egid=windscribe.
    # /run/wrappers/bin/Windscribe only exists after NixOS activation.
    makeWrapper $out/opt/windscribe/Windscribe $out/bin/windscribe-unwrapped \
      --prefix LD_LIBRARY_PATH : "$out/opt/windscribe/lib" \
      --prefix PATH : "$out/opt/windscribe"

    install -Dm755 ${./windscribe-launcher.sh} $out/bin/windscribe
    substituteInPlace $out/bin/windscribe --replace-fail '@out@' "$out"

    makeWrapper $out/opt/windscribe/windscribe-cli $out/bin/windscribe-cli \
      --prefix LD_LIBRARY_PATH : "$out/opt/windscribe/lib"

    ln -s $out/opt/windscribe/helper $out/bin/windscribe-helper

    if [ -f usr/share/applications/windscribe.desktop ]; then
      install -Dm644 usr/share/applications/windscribe.desktop \
        $out/share/applications/windscribe-vendor.desktop
      substituteInPlace $out/share/applications/windscribe-vendor.desktop \
        --replace-fail "Exec=/opt/windscribe/Windscribe %F" "Exec=windscribe %F"
    fi

    if [ -f etc/windscribe/autostart/windscribe.desktop ]; then
      install -Dm644 etc/windscribe/autostart/windscribe.desktop \
        $out/share/windscribe/autostart/windscribe.desktop
      substituteInPlace $out/share/windscribe/autostart/windscribe.desktop \
        --replace-fail "Exec=/opt/windscribe/Windscribe --autostart %F" "Exec=windscribe --autostart %F"
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "windscribe";
      desktopName = "Windscribe";
      exec = "windscribe %F";
      icon = "Windscribe";
      type = "Application";
      categories = [
        "Network"
        "System"
      ];
      startupWMClass = "Windscribe";
      comment = "Windscribe VPN client";
      terminal = false;
    })
  ];

  meta = {
    description = "Windscribe VPN desktop client";
    homepage = "https://github.com/Windscribe/Desktop-App";
    changelog = "https://github.com/Windscribe/Desktop-App/releases/tag/v${version}";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "windscribe";
  };
}
