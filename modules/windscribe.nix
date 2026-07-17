{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.windscribe;
  pkg = cfg.package;

  # Mirrors the .deb's /etc/windscribe/autostart/windscribe.desktop, pointing
  # at the setgid security wrapper (store paths cannot be chmod 2755).
  autostartDesktop = ''
    [Desktop Entry]
    Type=Application
    Terminal=false
    Exec=/run/wrappers/bin/Windscribe --autostart %F
    Name=Windscribe
    Icon=Windscribe
    Categories=Network
    StartupWMClass=Windscribe
    SingleMainWindow=true
  '';
in
{
  options.services.windscribe = {
    enable = lib.mkEnableOption "Windscribe VPN helper service and /opt/windscribe layout";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.windscribe;
      defaultText = lib.literalExpression "pkgs.windscribe";
      description = "Windscribe package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    # postinst: groupadd windscribe && useradd -r -g windscribe ...
    # Helper hard-requires this group and exits immediately without it:
    #   "Could not get group info for windscribe" → "Windscribe helper finished"
    users.groups.windscribe = { };
    users.users.windscribe = {
      isSystemUser = true;
      group = "windscribe";
      description = "Windscribe helper service";
    };

    # postinst: chgrp windscribe /opt/windscribe/Windscribe && chmod 2755
    # Nix store is immutable, so use a security wrapper instead. GUI must run
    # with egid=windscribe to talk to helper.sock and pass firewall owner checks.
    security.wrappers.Windscribe = {
      source = "${pkg}/opt/windscribe/Windscribe";
      owner = "root";
      group = "windscribe";
      setgid = true;
      permissions = "u+rx,g+rx,o+rx";
    };

    systemd.services.windscribe-helper = {
      description = "Windscribe helper service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-pre.target" ];
      before = [ "network-pre.target" ];
      after = [ "network-pre.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkg}/opt/windscribe/helper";
        Restart = "on-failure";
        RestartSec = 2;
        RuntimeDirectory = "windscribe";
        RuntimeDirectoryMode = "0750";
        StateDirectory = "windscribe";
        StateDirectoryMode = "0750";
        LogsDirectory = "windscribe";
        LogsDirectoryMode = "0755";
      };
    };

    # Helper/GUI hardcode /opt/windscribe for scripts and bundled libs.
    system.activationScripts.windscribe = lib.stringAfter [ "users" "groups" ] ''
      mkdir -p /opt /var/log/windscribe /var/lib/windscribe /run/windscribe /etc/windscribe/autostart
      ln -sfn ${pkg}/opt/windscribe /opt/windscribe
      chgrp -R windscribe /var/log/windscribe /var/lib/windscribe /run/windscribe 2>/dev/null || true
      chmod 0750 /var/lib/windscribe /run/windscribe 2>/dev/null || true
      chmod 0755 /var/log/windscribe 2>/dev/null || true
    '';

    environment.etc = {
      # postinst writes this platform marker.
      "windscribe/platform".text = "linux_deb_x64";
      "windscribe/autostart/windscribe.desktop".text = autostartDesktop;
    };

    # polkit/pkexec listed in the .deb Depends (privileged network ops).
    security.polkit.enable = true;

    environment.systemPackages = [
      pkg
      pkgs.iptables
      pkgs.iproute2
      pkgs.procps
      pkgs.psmisc
      pkgs.nettools
    ];
  };
}
