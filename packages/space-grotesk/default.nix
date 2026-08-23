# Space Grotesk — variable font (wght axis). Upstream dots-hyprland uses it for
# Quickshell UI text; not packaged individually in nixpkgs.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "space-grotesk";
  version = "2.0.0-vf";

  src = fetchurl {
    # google/fonts main branch, variable TTF (family last released as v2).
    url = "https://raw.githubusercontent.com/google/fonts/main/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf";
    hash = "sha256-rK1t4fyTQ29cDx9BN3Ue8E8a6jBj5wNlNZcP/PvXn3I=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/fonts/truetype/SpaceGrotesk-VF.ttf
    runHook postInstall
  '';

  meta = with lib; {
    description = "Space Grotesk variable font";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
