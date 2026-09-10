{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
  gst_all_1,
  elfutils,
  libunwind,
  systemd,
}:

let
  pname = "buzz";
  version = "0.5.22";

  src = fetchurl {
    url = "https://github.com/block/buzz/releases/download/desktop-v${version}/Buzz_${version}_amd64.AppImage";
    hash = "sha256-RxIQAaHJ7i+8MYZyMm7oor2T2RR4XBZaD8AJR+NJNbE=";
  };

  # Upstream AppImage strips bundled GStreamer and expects host plugins
  # (see buzz-desktop launcher shim). Provide a full plugin set.
  # Use lib outputs — `gstreamer` alone can resolve to the -bin output, which
  # has no lib/gstreamer-1.0 plugins.
  gstreamerPkgs = map lib.getLib (
    with gst_all_1;
    [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]
  );

  gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" gstreamerPkgs;
  gstPluginScanner = "${lib.getLib gst_all_1.gstreamer}/libexec/gstreamer-1.0/gst-plugin-scanner";

  # Upstream also removed bundled libsystemd (#2353). libsystemd pulls
  # libelf.so.1 (elfutils); neither is in appimageTools' default multiPkgs.
  systemLibs = [
    elfutils
    libunwind
    systemd
  ];

  # Patch the launcher so after it drops empty AppDir GST_* overrides we
  # inject nixpkgs plugin paths. Also disable WebKit's bwrap sandbox — child
  # WebKitWebProcess otherwise cannot see /nix/store plugins (blank media /
  # "appsink not found").
  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      substituteInPlace $out/usr/bin/buzz-desktop \
        --replace-fail \
          'exec -a "buzz-desktop" "$here/buzz-desktop.bin" "$@"' \
          'export GST_PLUGIN_SYSTEM_PATH_1_0="${gstPluginPath}''${GST_PLUGIN_SYSTEM_PATH_1_0:+:$GST_PLUGIN_SYSTEM_PATH_1_0}"
export GST_PLUGIN_PATH="${gstPluginPath}''${GST_PLUGIN_PATH:+:$GST_PLUGIN_PATH}"
export GST_PLUGIN_SCANNER="${gstPluginScanner}"
export GST_PLUGIN_SCANNER_1_0="${gstPluginScanner}"
# WebKit process sandbox cannot mount /nix/store plugin paths under bwrap.
export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS="''${WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS:-1}"
exec -a "buzz-desktop" "$here/buzz-desktop.bin" "$@"'
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraPkgs = pkgs: gstreamerPkgs ++ systemLibs;

  extraInstallCommands = ''
    source "${makeWrapper}/nix-support/setup-hook"

    install -Dm644 ${appimageContents}/usr/share/applications/Buzz.desktop \
      $out/share/applications/buzz.desktop

    substituteInPlace $out/share/applications/buzz.desktop \
      --replace-fail 'Exec=buzz-desktop' 'Exec=buzz' \
      --replace-fail 'Categories=' 'Categories=Network;Office;Chat;'

    if [ -d ${appimageContents}/usr/share/icons ]; then
      mkdir -p $out/share/icons
      cp -a ${appimageContents}/usr/share/icons/. $out/share/icons/
      chmod -R u+w $out/share/icons
    fi
    if [ -f ${appimageContents}/Buzz.png ]; then
      install -Dm644 ${appimageContents}/Buzz.png \
        $out/share/icons/hicolor/256x256/apps/buzz-desktop.png
    fi

    # GDK_BACKEND=wayland: avoid XWayland (blurry under Hyprland 1.5 scale).
    # WEBKIT_DISABLE_DMABUF_RENDERER: Intel + WebKit dma-buf often looks chunky.
    wrapProgram $out/bin/buzz \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}" \
      --prefix GST_PLUGIN_PATH : "${gstPluginPath}" \
      --set-default GST_PLUGIN_SCANNER "${gstPluginScanner}" \
      --set-default GST_PLUGIN_SCANNER_1_0 "${gstPluginScanner}" \
      --set-default WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS "1" \
      --set-default GDK_BACKEND "wayland" \
      --set-default WEBKIT_DISABLE_DMABUF_RENDERER "1"
  '';

  meta = {
    description = "Workspace where humans and agents build together (desktop client)";
    homepage = "https://github.com/block/buzz";
    changelog = "https://github.com/block/buzz/releases/tag/v${version}";
    downloadPage = "https://github.com/block/buzz/releases/tag/v${version}";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
