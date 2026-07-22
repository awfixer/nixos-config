{
  lib,
  stdenv,
  fetchurl,
  ostree,
  flatpak,
  makeWrapper,
  wrapGAppsHook4,
  bubblewrap,
  xdg-dbus-proxy,
  gsettings-desktop-schemas,
  dconf,
  # System libraries required by Orion's bundled WebKitGTK / GTK4 binary
  # (built against the GNOME Platform 49 flatpak runtime ABI).
  cairo,
  curl,
  enchant,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  graphene,
  gst_all_1,
  gtk4,
  harfbuzz,
  # ICU addon for harfbuzz (libharfbuzz-icu.so.0) required by bundled WebKit.
  harfbuzzFull,
  hyphen,
  icu77,
  lcms2,
  libadwaita,
  libavif,
  libdrm,
  libepoxy,
  libgcrypt,
  libGL,
  libgpg-error,
  libjpeg,
  libjxl,
  libmanette,
  libpng,
  libpulseaudio,
  libsecret,
  libsoup_3,
  libtasn1,
  libwebp,
  libx11,
  libxml2,
  libxslt,
  libgbm,
  pango,
  pipewire,
  pciutils,
  systemd,
  vulkan-loader,
  wayland,
  woff2,
  zlib,
  bzip2,
  xz,
  libseccomp,
}:

let
  pname = "orion-browser";
  version = "0.3.0";

  # Flatpak app-id / process name. 1Password custom_allowed_browsers must match
  # /proc/<pid>/comm (first 15 chars of the executable basename) → "oriongtk".
  binaryName = "oriongtk";
  appId = "com.kagi.OrionGtk";

  src = fetchurl {
    url = "https://orionbrowser.com/download/oriongtk.${version}.flatpak";
    hash = "sha256-0NOWPS2Yv5NpnTxqsiMvshHFyTyDotPi964/2og/bCw=";
  };

  gstPlugins = [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
  ];

  rpath = lib.makeLibraryPath (
    [
      cairo
      curl
      enchant
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      graphene
      gtk4
      harfbuzz
      harfbuzzFull
      hyphen
      icu77
      lcms2
      libadwaita
      libavif
      libdrm
      libepoxy
      libgcrypt
      libGL
      libgpg-error
      libjpeg
      libjxl
      libmanette
      libpng
      libpulseaudio
      libsecret
      libsoup_3
      libtasn1
      libwebp
      libx11
      libxml2
      libxslt
      libgbm
      pango
      pipewire
      systemd
      vulkan-loader
      wayland
      woff2
      zlib
      bzip2
      xz
      libseccomp
      stdenv.cc.cc
    ]
    ++ gstPlugins
  );

  gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" gstPlugins;

  # GLib looks under $XDG_DATA_DIRS/gsettings-schemas/<pkg>/glib-2.0/schemas
  # (plain …/share is not enough — causes schema_source_lookup source=NULL).
  gsettingsSchemaPath = lib.concatMapStringsSep ":" (p: "${p}/share/gsettings-schemas/${p.name}") [
    gsettings-desktop-schemas
    gtk4
    libadwaita
  ];
in
stdenv.mkDerivation rec {
  inherit pname version src;

  nativeBuildInputs = [
    ostree
    flatpak
    makeWrapper
    wrapGAppsHook4
  ];

  # Pull in GIO/GTK/GSettings for wrapGAppsHook4 (avoids
  # g_settings_schema_source_lookup: source != NULL).
  buildInputs = [
    glib
    gtk4
    libadwaita
    libsoup_3
    libsecret
    gsettings-desktop-schemas
    dconf
  ];

  dontConfigure = true;
  dontBuild = true;
  # We only wrap the launcher + WebKit helpers ourselves.
  dontWrapGApps = true;
  # Keep flatpak-style lib64 layout (rpaths + /app/lib64 symlink target).
  dontMoveLib64 = true;
  # Proprietary WebKit binary — stripping has broken similar packages before.
  dontStrip = true;
  # Keep full rpath we set for bundled + system libs (dlopen / helpers).
  dontShrinkRpath = true;

  # Avoid stdenv auto-detecting sourceRoot (ostree layout is nonstandard).
  setSourceRoot = "sourceRoot=source";

  unpackPhase = ''
    runHook preUnpack

    ostree init --repo=repo --mode=archive-z2
    flatpak build-import-bundle repo "$src"

    mkdir -p checkout
    ostree --repo=repo checkout --user-mode \
      app/${appId}/x86_64/master checkout/tree

    # Break ostree hardlinks into a normal writable tree for the builder.
    # (chmod/patchelf on hardlinked repo objects is unreliable in the sandbox.)
    if [ -d checkout/tree/files ]; then
      cp -a --no-preserve=ownership checkout/tree/files source
    elif [ -d checkout/tree/bin ]; then
      cp -a --no-preserve=ownership checkout/tree source
    else
      echo "unexpected flatpak tree:"
      find checkout -maxdepth 4 | head -80
      exit 1
    fi

    # Drop ostree repo + checkout to free space in the build dir.
    rm -rf repo checkout

    chmod -R u+w source
    cd source

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a bin lib lib64 libexec share $out/

    # Drop flatpak/build junk not needed at runtime.
    rm -rf $out/lib64/cmake $out/lib64/pkgconfig
    rm -f $out/bin/app.gdbserver.sh $out/bin/unifdef $out/bin/unifdefall
    rm -f $out/bin/WebKitWebDriver
    rm -rf $out/libexec/webkitgtk-6.0/MiniBrowser $out/libexec/webkitgtk-6.0/jsc
    rm -rf $out/share/app-info $out/share/gir-1.0
    rm -rf $out/lib/x86_64-linux-gnu
    rm -f $out/lib/libbacktrace.la

    # Desktop entry: keep app-id for icons; pass URL placeholders.
    if [ -f $out/share/applications/${appId}.desktop ]; then
      substituteInPlace $out/share/applications/${appId}.desktop \
        --replace-fail "Exec=${binaryName}" "Exec=${binaryName} %u"
    fi

    rpathOut="$out/lib64:$out/lib:${rpath}"

    # --- No bubblewrap / FHS ---
    # bwrap sets no_new_privs which strips setgid from 1Password-BrowserSupport
    # ("process detected it was running without libc's security, aborting").
    # Same workaround as packages/helium.
    for elf in \
      $out/bin/${binaryName} \
      $out/libexec/webkitgtk-6.0/WebKitWebProcess \
      $out/libexec/webkitgtk-6.0/WebKitNetworkProcess \
      $out/libexec/webkitgtk-6.0/WebKitGPUProcess
    do
      if [ -f "$elf" ] && [ -x "$elf" ]; then
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$elf" || true
        patchelf --set-rpath "$rpathOut" "$elf" || true
      fi
    done
    for so in $out/lib64/*.so* $out/lib64/webkitgtk-6.0/injected-bundle/*.so*; do
      if [ -f "$so" ]; then
        patchelf --set-rpath "$rpathOut" "$so" || true
      fi
    done

    # Real ELF under libexec, still basename "oriongtk" so after exec
    # /proc/self/comm matches 1Password custom_allowed_browsers.
    mv $out/bin/${binaryName} $out/libexec/${binaryName}

    # Bundled WebKit hardcodes /usr/bin/{bwrap,xdg-dbus-proxy} for the
    # *child* process sandbox. On NixOS those paths do not exist unless the
    # module installs tmpfiles symlinks — and even then, bwrap sets
    # no_new_privs on sandboxed children, which can break spawning
    # 1Password-BrowserSupport from extension/native-messaging paths.
    #
    # Disable WebKit's bubblewrap sandbox so:
    #   1) the browser starts without /usr/bin/bwrap
    #   2) NMH / 1Password keep setgid (same class of issue as Helium+FHS)
    # The *main* oriongtk process is still not wrapped in bwrap/FHS.
    # Module still ships /usr/bin/bwrap for optional re-enable later.
    makeWrapper $out/libexec/${binaryName} $out/bin/${binaryName} \
      "''${gappsWrapperArgs[@]}" \
      --argv0 ${binaryName} \
      --prefix LD_LIBRARY_PATH : "$rpathOut" \
      --prefix PATH : "${lib.makeBinPath [ pciutils bubblewrap xdg-dbus-proxy ]}" \
      --set WEBKIT_INJECTED_BUNDLE_PATH "$out/lib64/webkitgtk-6.0/injected-bundle" \
      --set WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS "1" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}" \
      --prefix XDG_DATA_DIRS : "${gsettingsSchemaPath}"

    # Wrap WebKit helpers (spawned via hardcoded /app/libexec/webkitgtk-6.0 →
    # symlinked to $out/libexec/webkitgtk-6.0 by the NixOS module).
    for helper in WebKitWebProcess WebKitNetworkProcess WebKitGPUProcess; do
      if [ -f $out/libexec/webkitgtk-6.0/$helper ]; then
        mv $out/libexec/webkitgtk-6.0/$helper \
          $out/libexec/webkitgtk-6.0/.$helper-unwrapped
        makeWrapper $out/libexec/webkitgtk-6.0/.$helper-unwrapped \
          $out/libexec/webkitgtk-6.0/$helper \
          --prefix LD_LIBRARY_PATH : "$rpathOut" \
          --prefix PATH : "${lib.makeBinPath [ bubblewrap xdg-dbus-proxy ]}" \
          --set WEBKIT_INJECTED_BUNDLE_PATH "$out/lib64/webkitgtk-6.0/injected-bundle" \
          --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"
      fi
    done

    runHook postInstall
  '';

  # Bundled WebKit looks up helpers at the compile-time path
  # /app/libexec/webkitgtk-6.0. The NixOS module symlinks that path to $out
  # without bubblewrap (which would break 1Password-BrowserSupport setgid).
  passthru = {
    inherit binaryName appId;
    webkitLibexecHostPath = "/app/libexec/webkitgtk-6.0";
  };

  meta = {
    description = "Orion Browser by Kagi (Linux GTK beta) — WebKit-based privacy browser";
    homepage = "https://orionbrowser.com";
    downloadPage = "https://orionbrowser.com/download/oriongtk.${version}.flatpak";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = binaryName;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
