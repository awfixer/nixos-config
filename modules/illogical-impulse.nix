# System-level services required by the illogical-impulse Quickshell desktop.
# (User-side side lives in home-manager/quickshell-ii.nix.)
#
# NOTE on PAM: ii's lock screen authenticates via Quickshell's
# `Quickshell.Services.Pam`, which reads /etc/pam.d/<config name>. The default
# config name is "qs" — the empty service below gives it standard unix auth
# (+ fingerprint when fprintd is present).
{ pkgs, ... }:

{
  # gsettings persistence for matugen/switchwall theme switches
  programs.dconf.enable = true;

  # Dolphin trash://, file watchers, mount dialogs
  services.gvfs.enable = true;

  # Location for the Weather widget (QtPositioning geoclue2 plugin in qs).
  services.geoclue2.enable = true;
  # Allow the shell binary to talk to geoclue without the demo agent.
  services.geoclue2.appConfig = {
    qs = {
      isAllowed = true;
      isSystem = false;
    };
    quickshell = {
      isAllowed = true;
      isSystem = false;
    };
  };

  # Daemon + socket (/run/ydotoold/socket) for `ydotool key` calls from the
  # on-screen keyboard service; session picks up YDOTOOL_SOCKET from
  # environment.variables set by this module.
  programs.ydotool.enable = true;
  users.users.awfixer.extraGroups = [ "ydotool" ];

  # Quickshell lock-screen authentication.
  security.pam.services.qs = { };

  environment.systemPackages = with pkgs; [
    # kcmshell6 modules used by the ii network/bluetooth panels:
    #   kcm_networkmanagement (plasma-nm), kcm_bluetooth (bluedevil)
    kdePackages.plasma-nm
    kdePackages.bluedevil
  ];
}
