{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
  alsa-lib,
  dbus,
  libglvnd,
  libx11,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

stdenv.mkDerivation rec {
  pname = "kraken-desktop";
  # Pinned against https://desktop-downloads.kraken.com/latest.json
  version = "1.27.0";

  src = fetchurl {
    url = "https://desktop-downloads.kraken.com/latest/kraken-x86_64-unknown-linux-gnu.zip";
    hash = "sha256-RJV16wokbwFWNtOW4L46LqaOFpKts59G2ejvOX405DU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];

  buildInputs = [
    alsa-lib
    dbus
    stdenv.cc.cc
  ];

  # iced/winit/wgpu dlopen these (not in DT_NEEDED).
  runtimeDependencies = [
    libglvnd
    libx11
    libxcb
    libxkbcommon
    vulkan-loader
    wayland
  ];

  # Zip unpacks files at the top level (no wrapping directory).
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  # Vendor iced/wgpu binary; stripping has broken similar prebuilts.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 kraken_desktop $out/bin/kraken_desktop
    ln -s kraken_desktop $out/bin/kraken

    install -Dm644 kraken.desktop $out/share/applications/kraken.desktop

    runHook postInstall
  '';

  meta = {
    description = "Kraken crypto exchange desktop client (charts, order books, time & sales)";
    homepage = "https://www.kraken.com/desktop";
    downloadPage = "https://desktop-downloads.kraken.com/latest/kraken-x86_64-unknown-linux-gnu.zip";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kraken_desktop";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
