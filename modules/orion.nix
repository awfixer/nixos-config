{ config, lib, pkgs, ... }:

let
  cfg = config.programs.orion-browser;
  pkg = cfg.package;
in
{
  options.programs.orion-browser = {
    enable = lib.mkEnableOption "Orion Browser (Kagi GTK beta)";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.orion-browser;
      description = "Orion browser package";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkg
      # Also on PATH for debugging; WebKit looks up absolute /usr/bin paths below.
      pkgs.bubblewrap
      pkgs.xdg-dbus-proxy
    ];

    # Bundled WebKit hardcodes several absolute host paths from the Flatpak
    # build. Symlink them to the store without wrapping the *main* browser in
    # bwrap/FHS (that would set no_new_privs and break 1Password-BrowserSupport
    # setgid — same rationale as packages/helium).
    #
    # WebKit *child* sandboxes do spawn /usr/bin/bwrap; that only affects
    # WebKitNetworkProcess/WebKitWebProcess, not the main oriongtk process
    # that launches Native Messaging hosts.
    systemd.tmpfiles.rules = [
      # Flatpak-style /app layout for helpers + locales
      "d /app 0755 root root -"
      "d /app/libexec 0755 root root -"
      "d /app/lib64 0755 root root -"
      "d /app/share 0755 root root -"
      "L+ /app/libexec/webkitgtk-6.0 - - - - ${pkg}/libexec/webkitgtk-6.0"
      "L+ /app/lib64/webkitgtk-6.0 - - - - ${pkg}/lib64/webkitgtk-6.0"
      "L+ /app/share/locale - - - - ${pkg}/share/locale"

      # WebKit sandbox tools (hardcoded in libwebkitgtk)
      "d /usr/bin 0755 root root -"
      "L+ /usr/bin/bwrap - - - - ${pkgs.bubblewrap}/bin/bwrap"
      "L+ /usr/bin/xdg-dbus-proxy - - - - ${pkgs.xdg-dbus-proxy}/bin/xdg-dbus-proxy"
    ];
  };
}
