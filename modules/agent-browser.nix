{
  config,
  lib,
  pkgs,
  ...
}:

# Vercel's agent-browser CLI (installed per-user via `bun i -g agent-browser`
# → ~/.bun/bin/agent-browser) auto-downloads Chrome-for-Testing into
# ~/.agent-browser/browsers/. That raw binary needs FHS shared libraries and
# dies on NixOS (exit 127, libgbm.so.1 missing). nixpkgs Chromium bundles all
# of its own dependencies, so point the CLI at it instead of its download.
let
  browserExecutable = "${pkgs.chromium}/bin/chromium";
in
{
  environment.systemPackages = with pkgs; [
    chromium # target of AGENT_BROWSER_EXECUTABLE_PATH
  ];

  environment.sessionVariables = {
    AGENT_BROWSER_EXECUTABLE_PATH = browserExecutable;
  };

  # Also export for non-login contexts (systemd user daemons spawned by IDEs).
  environment.variables = {
    AGENT_BROWSER_EXECUTABLE_PATH = browserExecutable;
  };
}
