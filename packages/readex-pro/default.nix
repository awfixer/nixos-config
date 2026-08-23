# Readex Pro — variable font (HEXP + wght axes). Used for illogical-impulse
# Quickshell UI text; not packaged individually in nixpkgs.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "readex-pro";
  version = "2024-vf";

  src = fetchurl {
    # google/fonts main branch, variable TTF.
    url = "https://raw.githubusercontent.com/google/fonts/main/ofl/readexpro/ReadexPro%5BHEXP,wght%5D.ttf";
    hash = "sha256-Jou6fh6POxTXmLP7DkDrqj/DkwjJrAAg4vr23xgcww4=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/fonts/truetype/ReadexPro-VF.ttf
    runHook postInstall
  '';

  meta = with lib; {
    description = "Readex Pro variable font";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
