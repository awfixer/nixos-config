{
  lib,
  pkgs,
  open-design,
  ...
}:

let
  od = open-design.packages.${pkgs.stdenv.hostPlatform.system};
  daemon = od.daemon;
  web = od.web;
  vela = pkgs.vela-cli;

  # Loopback only — matches modules/firewall.nix (no inbound holes).
  listenHost = "127.0.0.1";
  publicHost = "opendesign.local";
  publicOrigin = "http://${publicHost}";
  daemonPort = 7457;
  webPort = 80;
  dataDir = "/home/awfixer/.od";
  user = "awfixer";
  group = "users";

  seedPrefs = pkgs.writeText "open-design-seed-prefs.py" ''
    import json
    from pathlib import Path
    p = Path(${builtins.toJSON dataDir}) / "app-config.json"
    data = {}
    if p.exists():
        try:
            data = json.loads(p.read_text())
        except Exception:
            data = {}
    changed = False
    if not data.get("agentId"):
        data["agentId"] = "grok-build"
        changed = True
    models = data.setdefault("agentModels", {})
    gb = models.setdefault("grok-build", {})
    if not gb.get("model"):
        gb["model"] = "grok-4.6"
        changed = True
    if changed:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(data, indent=2) + "\n")
  '';

  # Same SSE contract as upstream nix/nixos.nix: no gzip on /api/*,
  # flush_interval -1, long timeouts. Bind loopback; Host must be
  # opendesign.local (not 127.0.0.1) or Helium's Origin/Host fail CSRF.
  caddyfile = pkgs.writeText "open-design.Caddyfile" ''
    {
      auto_https off
      admin off
      persist_config off
    }

    http://${publicHost}:${toString webPort} {
      bind ${listenHost}

      handle /api/* {
        reverse_proxy ${listenHost}:${toString daemonPort} {
          flush_interval -1
          transport http {
            read_timeout 86400s
            write_timeout 86400s
          }
        }
      }
      handle /artifacts/* {
        reverse_proxy ${listenHost}:${toString daemonPort}
      }
      handle /frames/* {
        reverse_proxy ${listenHost}:${toString daemonPort}
      }
      handle {
        root * ${web}
        try_files {path} {path}/ /index.html
        file_server
        encode gzip
      }
    }
  '';

  # systemd system units start with a tiny PATH. The daemon finds
  # claude/codex/… by scanning PATH at runtime.
  daemonPath = lib.concatStringsSep ":" [
    "${vela}/bin"
    "/run/wrappers/bin"
    "/etc/profiles/per-user/${user}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/home/${user}/.nix-profile/bin"
    "/home/${user}/.local/bin"
    "/usr/bin"
    "/bin"
  ];
in
{
  # /etc/hosts wins over Avahi: NixOS prepends `files` in nsswitch, so
  # this does not fight Spotify's nssmdns4. Do not avahi-publish
  # 127.0.0.1 — LAN clients would resolve the name to themselves.
  environment.systemPackages = [
    daemon
    vela
  ];

  networking.hosts.${listenHost} = [ publicHost ];

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 ${user} ${group} -"
  ];

  systemd.services.open-design = {
    description = "Open Design daemon (od API)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      OD_PORT = toString daemonPort;
      OD_DATA_DIR = dataDir;
      # Caddy is :80 with Host opendesign.local — whitelist both.
      OD_WEB_PORT = toString webPort;
      OD_ALLOWED_ORIGINS = publicOrigin;
      PATH = lib.mkForce daemonPath;
      # Login / AMR Cloud (`vela login`) — not the Grok Build agent.
      VELA_BIN = lib.getExe vela;
      VELA_OPENCODE_BIN = "${vela}/bin/libexec/opencode/opencode";
      # So `vela login` can open Helium from this system unit.
      BROWSER = lib.getExe pkgs.helium-browser;
      XDG_RUNTIME_DIR = "/run/user/1000";
    };

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      ExecStartPre = "${pkgs.python3}/bin/python3 ${seedPrefs}";
      ExecStart = "${lib.getExe daemon} --port ${toString daemonPort} --no-open";
      Restart = "on-failure";
      RestartSec = 3;
      NoNewPrivileges = true;
      PrivateTmp = true;
      # ~/.od and agent creds (~/.claude, …) live in the user home.
      ProtectHome = false;
      OOMScoreAdjust = 200;
    };
  };

  systemd.services.open-design-web = {
    description = "Open Design web UI (${publicOrigin})";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "open-design.service"
    ];
    wants = [ "open-design.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.caddy} run --config ${caddyfile} --adapter caddyfile";
      Restart = "on-failure";
      RestartSec = 3;
      DynamicUser = true;
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
    };
  };
}
