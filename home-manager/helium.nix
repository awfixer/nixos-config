{ config, pkgs, lib, ... }:

let
  extDir = "${config.xdg.dataHome}/helium-devtools/extension";
  heliumOpen = "${pkgs.helium-devtools}/bin/helium-open";
  # webbrowser crate and grok MCP OAuth both spawn $BROWSER. Log every
  # invocation so we can tell whether Grok actually called it.
  grokBrowser = pkgs.writeShellScriptBin "grok-browser" ''
    mkdir -p "$HOME/.local/state"
    printf '%s grok-browser pid=%s argv=%s\n' "$(date -Iseconds)" "$$" "$*" >>"$HOME/.local/state/helium-open.log"
    exec ${lib.escapeShellArg heliumOpen} "$@"
  '';
  grokBrowserBin = lib.getExe grokBrowser;
  heliumWrapped = pkgs.symlinkJoin {
    name = "helium-browser-devtools";
    paths = [ pkgs.helium-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Helium (Chromium 151) rejects --remote-debugging-port on the
      # default profile and then skips inspect-mode startup entirely.
      # Seed Local State instead so helium://inspect remote debugging
      # comes up on every launch. Skip when SingletonLock exists.
      #
      # grok-build (webbrowser crate) runs `$BROWSER <oauth-url>`. A second
      # helium process with --load-extension often fails to hand the URL to
      # the existing window. Prefer the loopback CDP shim (PUT /json/new)
      # which creates the tab through the already-loaded extension.
      wrapProgram $out/bin/helium \
        --run "${pkgs.helium-devtools}/bin/helium-devtools-seed-remote-debugging >/dev/null 2>&1 || true" \
        --run 'if ${heliumOpen} --if-running "$@"; then exit 0; fi' \
        --add-flags "--load-extension=${extDir}" \
        --add-flags "--disable-features=DisableLoadExtensionCommandLineSwitch" \
        --add-flags "--silent-debugger-extension-api" \
        --add-flags "--disable-infobars" \
        --add-flags "--exclude-switches=enable-automation"
    '';
  };
in
{
  home.packages = [
    heliumWrapped
    grokBrowser
  ];

  # webbrowser crate tries $BROWSER first. The `open` crate / Ghostty
  # ctrl+click use xdg-open (desktop file). Point both at helium-open.
  home.sessionVariables.BROWSER = grokBrowserBin;
  systemd.user.sessionVariables.BROWSER = grokBrowserBin;

  # ~/.local/bin is ahead of /run/current-system on this machine's PATH, so
  # grok's `xdg-open` (Rust `open` crate) hits this before NixOS xdg-utils.
  home.file.".local/bin/xdg-open" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      mkdir -p "$HOME/.local/state"
      printf '%s xdg-open pid=%s argv=%s\n' "$(date -Iseconds)" "$$" "$*" >>"$HOME/.local/state/helium-open.log"
      case "''${1-}" in
        http://*|https://*)
          exec ${lib.escapeShellArg heliumOpen} "$@"
          ;;
      esac
      exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
    '';
  };

  # Ghostty ctrl+click / xdg-open use the desktop file, not $BROWSER.
  # Point Exec at helium-open so OSC-8 and portal OpenURI hit the CDP tab
  # path instead of a second Chromium instance.
  xdg.desktopEntries.helium = {
    name = "Helium";
    genericName = "Web Browser";
    comment = "Access the Internet";
    exec = "${grokBrowserBin} %U";
    icon = "helium";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
    settings.StartupNotify = "true";
  };
}
