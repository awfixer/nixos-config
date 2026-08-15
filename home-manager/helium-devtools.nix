{
  config,
  lib,
  pkgs,
  ...
}:

let
  tokenPath = "${config.xdg.dataHome}/helium-devtools/token";
in
{
  home.packages = [ pkgs.helium-devtools ];

  home.file.".grok/plugins/helium-devtools".source = ../ai;

  home.activation.heliumDevtoolsToken = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
    dir="${config.xdg.dataHome}/helium-devtools"
    mkdir -p "$dir/extension"
    chmod 700 "$dir" "$dir/extension"
    # Real files next to config.json. GNU install follows leftover
    # store-symlinks into /nix/store (EROFS); remove dest first.
    rm -f "$dir/extension/manifest.json" \
      "$dir/extension/background.js" \
      "$dir/extension/popup.html" \
      "$dir/extension/popup.js" \
      "$dir/extension/offscreen.html" \
      "$dir/extension/offscreen.js"
    install -m 644 ${../ai/extension/manifest.json} "$dir/extension/manifest.json"
    install -m 644 ${../ai/extension/background.js} "$dir/extension/background.js"
    install -m 644 ${../ai/extension/popup.html} "$dir/extension/popup.html"
    install -m 644 ${../ai/extension/popup.js} "$dir/extension/popup.js"
    install -m 644 ${../ai/extension/offscreen.html} "$dir/extension/offscreen.html"
    install -m 644 ${../ai/extension/offscreen.js} "$dir/extension/offscreen.js"
    if [ ! -f "$dir/token" ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$dir/token"
      chmod 600 "$dir/token"
    fi
    token=$(cat "$dir/token")
    umask 077
    printf '%s\n' "{\"bridgeUrl\":\"ws://127.0.0.1:17320\",\"token\":\"$token\"}" > "$dir/extension/config.json"
    chmod 600 "$dir/extension/config.json"
    # Persist helium://inspect remote debugging across rebuilds. No-op
    # while Helium holds SingletonLock (next launch seeds via wrapper).
    ${pkgs.helium-devtools}/bin/helium-devtools-seed-remote-debugging \
      --user-data-dir "${config.xdg.configHome}/net.imput.helium" || true
  '';

  systemd.user.services.helium-devtools = {
    Unit = {
      Description = "Helium DevTools MCP (CDP shim + chrome-devtools-mcp)";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.helium-devtools}/bin/helium-devtools";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=1"
        "CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1"
        "HELIUM_DEVTOOLS_TOKEN_FILE=${tokenPath}"
        "HELIUM_USER_DATA_DIR=%h/.config/net.imput.helium"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
