{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation rec {
  pname = "gloomberb";
  version = "0.10.5";

  src = fetchurl {
    url = "https://github.com/gloom-sh/gloomberb/releases/download/v${version}/gloomberb-linux-x64.gz";
    hash = "sha256-nVX0CbYv5eOWR2uoL4i4AWphfHmRKWDd4tBqN5hA9I8=";
  };

  # Single gzipped ELF, not a source tree.
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # Bun standalone ELFs store the bytecode payload in non-alloc sections;
  # `strip -S` drops it and the binary falls back to the raw bun CLI.
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "Gloomberb";
      comment = "Open-source finance terminal";
      exec = "${pname}";
      terminal = true;
      categories = [
        "Office"
        "Finance"
      ];
      keywords = [
        "stocks"
        "finance"
        "terminal"
        "tui"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    gzip -dc $src > $out/bin/${pname}
    chmod +x $out/bin/${pname}

    runHook postInstall
  '';

  meta = {
    description = "Open-source finance terminal for the terminal";
    homepage = "https://github.com/gloom-sh/gloomberb";
    changelog = "https://github.com/gloom-sh/gloomberb/releases/tag/v${version}";
    downloadPage = "https://github.com/gloom-sh/gloomberb/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
