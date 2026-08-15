{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "vela-cli";
  version = "0.0.33";

  # Pinned to tools/pack/package.json in nexu-io/open-design.
  # Layout must keep libexec/opencode next to bin/vela — AMR resolves
  # dirname(VELA_BIN)/libexec/opencode/opencode.
  src = fetchurl {
    url = "https://registry.npmjs.org/@powerformer/vela-cli-linux-x64/-/vela-cli-linux-x64-${version}.tgz";
    hash = "sha256-E2sKhJO6PhUpFka/5GFwd/0y3DV2DORqCFYv/L//vi0=";
  };

  sourceRoot = "package";
  dontConfigure = true;
  dontBuild = true;
  # Native npm binaries (Go/bun-style); strip can drop embedded payloads.
  dontStrip = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin/libexec/opencode
    install -Dm755 bin/vela $out/bin/vela
    install -Dm755 bin/libexec/opencode/opencode $out/bin/libexec/opencode/opencode
    runHook postInstall
  '';

  meta = {
    description = "Open Design AMR / Vela CLI (login + cloud runtime)";
    homepage = "https://www.npmjs.com/package/@powerformer/vela-cli";
    license = lib.licenses.unlicense;
    platforms = [ "x86_64-linux" ];
    mainProgram = "vela";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
