{ lib, pkgs, inputs ? null, ... }:

pkgs.appimageTools.wrapType2 rec {
  pname = "cursor";
  version = "0.34.2";
  src = pkgs.fetchurl {
    url = "https://dl.cursor.sh/prod/5212c074-9840-4999-a681-3141f238c353/linux/appimage/x64";
    name = "${pname}-${version}.AppImage";
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
