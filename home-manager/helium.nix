{ config, pkgs, lib, ... }:

let
  extDir = "${config.xdg.dataHome}/helium-devtools/extension";
  heliumWrapped = pkgs.symlinkJoin {
    name = "helium-browser-devtools";
    paths = [ pkgs.helium-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/helium \
        --add-flags "--load-extension=${extDir}" \
        --add-flags "--disable-features=DisableLoadExtensionCommandLineSwitch"
    '';
  };
in
{
  home.packages = [ heliumWrapped ];

  home.sessionVariables.BROWSER = "helium";
}
