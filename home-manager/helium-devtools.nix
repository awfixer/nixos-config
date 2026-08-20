{
  config,
  lib,
  pkgs,
  ...
}:

let
  tokenPath = "${config.xdg.dataHome}/helium-devtools/token";
  # Keep the Home Manager *target* at ~/.grok/plugins/helium-devtools so Grok
  # enablement, auto-trust, and MCP discovery survive the ai/ → ai/helium-devtools
  # source move. Only the Nix source path changed.
  pluginRoot = ../ai/helium-devtools;
  ext = pluginRoot + "/extension";
  required = {
    pluginJson = pluginRoot + "/.grok-plugin/plugin.json";
    mcp = pluginRoot + "/.mcp.json";
    skill = pluginRoot + "/skills/helium-devtools/SKILL.md";
    debugSkill = pluginRoot + "/skills/helium-debug-site/SKILL.md";
    agent = pluginRoot + "/agents/helium-debugger.md";
    manifest = ext + "/manifest.json";
    background = ext + "/background.js";
    popupHtml = ext + "/popup.html";
    popupJs = ext + "/popup.js";
    offscreenHtml = ext + "/offscreen.html";
    offscreenJs = ext + "/offscreen.js";
  };
  missing = lib.filter (name: !(builtins.pathExists required.${name})) (lib.attrNames required);
in
assert missing == [ ] || throw "helium-devtools plugin incomplete under ai/helium-devtools: missing ${lib.concatStringsSep ", " missing}";
{
  home.packages = [ pkgs.helium-devtools ];

  home.file.".grok/plugins/helium-devtools".source = pluginRoot;

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
    install -m 644 ${required.manifest} "$dir/extension/manifest.json"
    install -m 644 ${required.background} "$dir/extension/background.js"
    install -m 644 ${required.popupHtml} "$dir/extension/popup.html"
    install -m 644 ${required.popupJs} "$dir/extension/popup.js"
    install -m 644 ${required.offscreenHtml} "$dir/extension/offscreen.html"
    install -m 644 ${required.offscreenJs} "$dir/extension/offscreen.js"
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
      MemoryAccounting = true;
      MemoryHigh = "160M";
      MemoryMax = "220M";
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
