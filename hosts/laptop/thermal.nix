{ lib, pkgs, ... }:

{
  # ---------------------------------------------------------------------------
  # MacBook9,1 (m3-6Y30) thermal keep-alive
  #
  # Observed on 6.18.49: applesmc logs `key=701 fan=0` — SMC FNum is 0 so
  # the in-tree driver never creates fan sysfs. The fan still exists (F0Ac).
  # intel_rapl meanwhile exposes PL1/PL2 = 49 W on a 4.5 W part, and
  # power-profiles-daemon was left on `performance`. Idle → ~20 min →
  # chassis thermal poweroff. The daemon now caps RAPL at 15/22 W (not
  # datasheet 4.5/7 — that plus EPP=power pinned clocks at ~600 MHz).
  #
  # Do not rebuild the kernel here: compiling linux on this 4.5 W dual-core
  # will cook it. Userspace talks to the SMC the same way applesmc.c does.
  # ---------------------------------------------------------------------------

  environment.systemPackages = [ pkgs.macbook-thermal ];

  # applesmc holds the 0x300 I/O ports and races our SMC writes. It also
  # contributes nothing useful on this board (fan=0, acc=0, kbd=0).
  boot.blacklistedKernelModules = [ "applesmc" ];
  boot.kernelModules = [
    "coretemp"
    "intel_rapl_msr"
  ];

  # TLP fights power-profiles-daemon (already enabled for Hyprland widgets).
  # `balanced` (not `performance`, which cooked the chassis, and not
  # `power-saver`, which pinned the m3 at ~600 MHz). The thermal daemon
  # still drops EPP to `power` and disables turbo if the package gets hot.
  systemd.services.macbook-power-profile = {
    description = "MacBook9,1 default balanced power profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced";
    };
  };

  systemd.services.macbook-thermal = {
    description = "MacBook9,1 RAPL cap + SMC fan curve";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-modules-load.service"
      "systemd-udev-settle.service"
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.macbook-thermal}";
      Restart = "always";
      RestartSec = "2s";
      # May already be gone (blacklist) or still loaded from this boot.
      ExecStartPre = "-${pkgs.kmod}/bin/rmmod applesmc";
    };
  };
}
