{
  config,
  lib,
  pkgs,
  ...
}:

let
  bunHome = "${config.home.homeDirectory}/.bun";

  # CLIs installed with `bun add --global`. This list is *not* materialized as
  # home.file — a store symlink would make ~/.bun/install/global (and often the
  # sibling cache) read-only, which breaks every later `bun add` / `bun install`.
  # Activation writes through Bun into the real, mutable dirs instead.
  # Extra globals you `bun add -g` by hand are left alone (not pruned).
  globalPackages = [
    "@21st-dev/cli"
    "@earendil-works/pi-agent-core"
    "@earendil-works/pi-telemetry"
    "@earendil-works/chord"
    "@earendil-works/pi-ai"
    "@earendil-works/pi-tui"
    "@cline/cli-linux-x64"
    "@earendil-works/pi-coding-agent"
    "agent-browser"
    "clerk"
    "command-code"
  ];
in
{
  home.file.".grok/plugins/bun".source = ../ai/bun;

  home.file.".bunfig.toml".text = ''
    [install]
    minimumReleaseAge = 259200
    minimumReleaseAgeExcludes = [
      "@earendil-works/pi-agent-core",
      "@earendil-works/chord",
      "@earendil-works/pi-ai",
      "@earendil-works/pi-tui",
      "railway",
      "@earendil-works/pi-coding-agent",
      "clerk",
      "@clerk/cli-linux-x64",
      "@earendil-works/pi-telemetry"
    ]
    optional = false
    peer = false
    exact = true
    ignoreScripts = true
    auto = "disable"
    prefer = "offline"
    linkWorkspacePackages = true
    # Defaults — listed so we never point these at a store path.
    globalDir = "~/.bun/install/global"
    globalBinDir = "~/.bun/bin"

    [run]
    shell = "bun"
    noOrphans = true

    [test]
    coverageThreshold = 0.9

  '';

  # PATH for login shells / systemd user units. zsh.nix also prepends this.
  home.sessionVariables.BUN_INSTALL = bunHome;
  home.sessionPath = [ "${bunHome}/bin" ];

  # Official installer: https://bun.com/docs/installation
  # Upgrade once present: https://bun.com/guides/util/upgrade
  # Globals: https://bun.com/docs/pm/cli/add#global
  # The installer only edits ~/.zshrc when `bun` is missing from PATH *and*
  # the file is writable. Home Manager owns zshrc (store symlink), so PATH
  # comes from sessionPath / zsh.nix instead.
  home.activation.bun = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
    export BUN_INSTALL=${lib.escapeShellArg bunHome}
    export PATH="$BUN_INSTALL/bin:${pkgs.curl}/bin:${pkgs.unzip}/bin:$PATH"

    if [ -n "''${DRY_RUN_CMD:-}" ]; then
      echo "bun: would install/upgrade bun and ensure ${toString (builtins.length globalPackages)} global packages"
    else
      mkdir -p "$BUN_INSTALL/bin" "$BUN_INSTALL/install/cache" "$BUN_INSTALL/install/global"
      if [ ! -x "$BUN_INSTALL/bin/bun" ]; then
        echo "bun: installing latest via https://bun.sh/install"
        ${pkgs.curl}/bin/curl -fsSL https://bun.sh/install | ${pkgs.bash}/bin/bash \
          || echo "bun: official installer failed (offline?)" >&2
      else
        echo "bun: upgrading to latest ($("$BUN_INSTALL/bin/bun" --version))"
        "$BUN_INSTALL/bin/bun" upgrade \
          || echo "bun: upgrade skipped (already latest or offline)" >&2
      fi

      if [ -x "$BUN_INSTALL/bin/bun" ]; then
        echo "bun: ensuring global packages"
        "$BUN_INSTALL/bin/bun" add --global --prefer-latest \
          ${lib.escapeShellArgs globalPackages} \
          || echo "bun: global add skipped (offline or registry?)" >&2
      fi
    fi
  '';
}
