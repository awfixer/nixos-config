{
  lib,
  stdenv,
  zig,
  pkg-config,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  gtk4,
  webkitgtk_6_0,
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
  ];

  buildInputs = [
    gtk4
    webkitgtk_6_0
  ];

  dontConfigure = true;

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
