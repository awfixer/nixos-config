{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  copyDesktopItems,
  makeDesktopItem,
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
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  libpulseaudio,
  pciutils,
}:

let
  pname = "openwork";
  version = "0.18.25";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchzip {
    url = "https://github.com/different-ai/openwork/releases/download/v${version}/openwork-linux-x64-${version}.tar.gz";
    hash = "sha256-5E78OCRc8lNosy4JWZlQXeVpMDZu+uwhSTrbozKkKTg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
    copyDesktopItems
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
    libsecret
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc
  ];

  runtimeDependencies = [
    libGL
    vulkan-loader
    wayland
    pipewire
    systemd
    libpulseaudio
    pciutils
  ];

  appendRunpaths = [
    "${libGL}/lib"
    "${lib.getLib vulkan-loader}/lib"
    "${wayland}/lib"
    "${pipewire}/lib"
  ];

  # Unused better-sqlite3 musl prebuilds ship in the Linux x64 tarball.
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
  ];

  dontConfigure = true;
  dontBuild = true;
  # Only wrap the launcher; skip the Electron helpers and Bun sidecar.
  dontWrapGApps = true;
  # Bundled Electron / Bun sidecars store payloads in non-alloc sections.
  dontStrip = true;

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "OpenWork";
      comment = "Run agents, skills, and MCP workflows";
      exec = "${pname} %U";
      icon = pname;
      startupWMClass = "OpenWork";
      terminal = false;
      categories = [
        "Development"
        "Utility"
      ];
      mimeTypes = [ "x-scheme-handler/openwork" ];
      keywords = [
        "AI"
        "agent"
        "opencode"
        "workflow"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${pname}
    cp -a . $out/share/${pname}
    chmod -R u+w $out/share/${pname}

    # Prefer nixpkgs' vulkan loader over the bundled copy (same as helium).
    if [ -e $out/share/${pname}/libvulkan.so.1 ]; then
      rm -f $out/share/${pname}/libvulkan.so.1
      ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $out/share/${pname}/libvulkan.so.1
    fi

    for size in 16 24 32 48 64 96 128 256 512; do
      install -Dm644 resources/icons/linux/''${size}x''${size}.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
    done
    install -Dm644 resources/app-dist/openwork-logo-square.svg \
      $out/share/icons/hicolor/scalable/apps/${pname}.svg

    runHook postInstall
  '';

  # wrapGAppsHook fills gappsWrapperArgs after install; wrap here so GTK
  # schemas / XDG dirs actually land on the launcher.
  # chrome-sandbox cannot be setuid in the Nix store.
  preFixup = ''
    makeWrapper $out/share/${pname}/openwork $out/bin/openwork \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "$out/share/${pname}" \
      --prefix PATH : "${lib.makeBinPath [ pciutils ]}" \
      --add-flags "--no-sandbox" \
      --add-flags "--js-flags=--max-old-space-size=256" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  meta = {
    description = "Open-source desktop app for sharing AI workflows (Claude Cowork alternative)";
    homepage = "https://github.com/different-ai/openwork";
    changelog = "https://github.com/different-ai/openwork/releases/tag/v${version}";
    downloadPage = "https://github.com/different-ai/openwork/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
