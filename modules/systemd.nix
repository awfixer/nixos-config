{ lib, ... }:

{
  # ---------------------------------------------------------------------------
  # OOM killers — userspace off; kernel OOM de-fanged; no cascade unit kills.
  # Real headroom comes from modules/memory.nix (zram + disk swap).
  # ---------------------------------------------------------------------------

  systemd.oomd = {
    enable = false;
    enableRootSlice = false;
    enableSystemSlice = false;
    enableUserSlices = false;
  };

  services.earlyoom.enable = false;

  # System manager: do not stop units when a child is OOM-killed.
  systemd.settings.Manager = {
    DefaultOOMPolicy = "continue";
    DefaultOOMScoreAdjust = 0;
    DefaultIOAccounting = false;
    DefaultIPAccounting = false;
  };

  # User manager (ghostty scopes, qs, etc.): same policy — this is what
  # previously mass-SIGKILLed grok after rustc died in the ghostty surface scope.
  systemd.user.settings.Manager = {
    DefaultOOMPolicy = "continue";
    DefaultIOAccounting = false;
    DefaultIPAccounting = false;
  };

  boot.kernel.sysctl = {
    "vm.panic_on_oom" = 0;
    "vm.oom_kill_allocating_task" = 0;
    "vm.overcommit_memory" = 1;
    "vm.oom_dump_tasks" = 0;
  };

  # Prefer not to OOM-pick the login session / secrets path first.
  systemd.services."user@" = {
    serviceConfig = {
      OOMPolicy = "continue";
      OOMScoreAdjust = -200;
    };
  };

  # ---------------------------------------------------------------------------
  # Slim background surface (keep display, net, audio, keyring, BT)
  # Optional daemons: enable = false only — leave config for easy re-enable.
  # ---------------------------------------------------------------------------

  networking.modemmanager.enable = false;

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;

  services.packagekit.enable = false;
  services.speechd.enable = false;
  services.gnome.gnome-online-accounts.enable = false;
  services.gnome.gcr-ssh-agent.enable = false;
  services.gnome.evolution-data-server.enable = false;
  services.gnome.localsearch.enable = false;
  services.gnome.tinysparql.enable = false;

  # No printers / firmware-update daemon on this laptop.
  # mDNS/avahi is owned by modules/spotify.nix (Connect + LAN speaker discovery).
  # geoclue2 is enabled in modules/illogical-impulse.nix (ii Weather widget).
  services.printing.enable = false;
  services.fwupd.enable = false;
  services.colord.enable = false;
  services.sysprof.enable = false;
  services.tlp.enable = false;
  # Bluetooth lives in services.nix (needed for speakers / peripherals).

  # Optional noise units.
  systemd.coredump.enable = false;
  systemd.services.systemd-pstore.enable = false;
  systemd.services.systemd-machined.enable = false;
  systemd.sockets.systemd-machined.enable = false;
  systemd.services.systemd-importd.enable = false;
  systemd.sockets.systemd-importd.enable = false;
  # hostnamed is rarely needed; socket-activates if something asks.
  systemd.services.systemd-hostnamed.enable = lib.mkDefault false;

  services.journald = {
    extraConfig = ''
      SystemMaxUse=50M
      RuntimeMaxUse=32M
      MaxRetentionSec=3day
      MaxFileSec=1day
      Storage=persistent
      Compress=yes
    '';
    rateLimitBurst = 100;
    rateLimitInterval = "30s";
  };

  documentation = {
    enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };

  systemd.tmpfiles.rules = [
    "d /etc/atuin 0755 root root -"
  ];

  # ---------------------------------------------------------------------------
  # User session: protect keyring; kill leftover agents
  # ---------------------------------------------------------------------------
  systemd.user.services.gnome-keyring = {
    serviceConfig = {
      OOMPolicy = "continue";
      OOMScoreAdjust = -800;
    };
  };

  systemd.user.services.gcr-ssh-agent.enable = false;
  systemd.user.sockets.gcr-ssh-agent.enable = false;
  systemd.user.services.speech-dispatcher.enable = false;
  systemd.user.sockets.speech-dispatcher.enable = lib.mkDefault false;
  # Bluetooth OBEX (file push) — not needed; pair/A2DP still work without it.
  systemd.user.services.obex.enable = false;

}

