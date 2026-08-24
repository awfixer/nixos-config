{
  lib,
  stdenv,
  zig,
  pkg-config,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  gtk4,
  webkitgtk_6_0,
  glib-networking,
}:

stdenv.mkDerivation {
  pname = "brave-search";
  version = "0.1.0";

  src = ./.;

  # zig build resolves gtk/webkit via pkg-config; no vendored deps, no network.
  nativeBuildInputs = [
    zig
    pkg-config
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = [
    gtk4
    webkitgtk_6_0
    # Provides the GIO TLS module — without it every https:// load fails
    # with WebKit's "TLS not available" error.
    glib-networking
  ];

  dontConfigure = true;

  postFixup = ''
    wrapProgram "$out/bin/brave-search" \
      --set GIO_MODULE_DIR "${glib-networking}/lib/gio/modules"
  '';

  buildPhase = ''
    runHook preBuild

    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-global-cache
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-local-cache

    zig build install -Doptimize=ReleaseSafe -p $out

    runHook postBuild
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "brave-search";
      desktopName = "Brave Search";
      comment = "Minimal Brave Search window";
      exec = "brave-search %U";
      tryExec = "brave-search";
      icon = "web-browser";
      categories = [
        "Network"
        "Utility"
      ];
      keywords = [
        "search"
        "brave"
        "web"
        "query"
      ];
      startupWMClass = "com.awfixer.BraveSearch";
      terminal = false;
    })
  ];

  meta = {
    description = "Chromeless native WebKit window for search.brave.com";
    longDescription = ''
      Single-window WebKitGTK (GTK4) shell around Brave Search, written in Zig.
      Launches from any desktop launcher; extra arguments are treated as a
      search query or URL. Re-launching reuses the existing window. Links that
      leave search.brave.com are handed to xdg-open.
    '';
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "brave-search";
  };
}
