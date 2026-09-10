{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "macbook-thermal";
  version = "1.0.0";

  src = ./.;

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    $CC -O2 -Wall -Wextra -Werror -o macbook-thermal macbook-thermal.c
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 macbook-thermal $out/bin/macbook-thermal
    runHook postInstall
  '';

  meta = {
    description = "MacBook9,1 RAPL cap + SMC fan control (FNum=0 workaround)";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "macbook-thermal";
  };
}
