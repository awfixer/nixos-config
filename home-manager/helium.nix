{ config, pkgs, lib, ... }:

let
  extDir = "${config.xdg.dataHome}/helium-devtools/extension";
  heliumWrapped = pkgs.symlinkJoin {
    name = "helium-browser-devtools";
    paths = [ pkgs.helium-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Helium (Chromium 151) rejects --remote-debugging-port on the
      # default profile and then skips inspect-mode startup entirely.
      # Seed Local State instead so helium://inspect remote debugging
      # comes up on every launch. Skip when SingletonLock exists.
      wrapProgram $out/bin/helium \
        --run "${pkgs.helium-devtools}/bin/helium-devtools-seed-remote-debugging >/dev/null 2>&1 || true" \
        --add-flags "--load-extension=${extDir}" \
        --add-flags "--disable-features=DisableLoadExtensionCommandLineSwitch" \
        --add-flags "--silent-debugger-extension-api" \
        --add-flags "--disable-infobars" \
        --add-flags "--exclude-switches=enable-automation"
    '';
  };
in
{
  home.packages = [ heliumWrapped ];

  home.sessionVariables.BROWSER = "helium";
}
