{ lib, pkgs, inputs ? null, ... }:

pkgs.appimageTools.wrapType2 rec {
  pname = "Cursor";
  version = "1.7.46";
  src = pkgs.fetchurl {
    url = "https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/1.7";
    name = "Cursor-1.7.46-x86_64.AppImage";
    hash = "sha256-09q3na5p5xshm67axb769fdh82n9gjc8zixg6h283595cmg47s1n";
  };
  meta = {
    description = "The AI-first Code Editor";
    homepage = "https://cursor.sh/";
    downloadPage = "https://cursor.sh/download";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ onny ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
}
