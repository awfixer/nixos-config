{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  makeWrapper,
}:

let
  pname = "helium";
  version = "0.14.5.1";
in
appimageTools.wrapType2 rec {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-x86_64.AppImage";
    hash = "sha256-JM4Tm4Le9Xcfq3fFMEu/DIK6817FEgBQ2rSwY093F04=";
  };

  extraPkgs = pkgs: [ pkgs.libva ];

  extraBwrapArgs = [
    "--ro-bind-try /etc/chromium /etc/chromium"
  ];

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${contents}/usr/share/icons $out/share
    '';

  meta = {
    description = "Private, fast, and honest web browser based on Chromium";
    homepage = "https://github.com/imputnet/helium-chromium";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${version}";
    license = lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
