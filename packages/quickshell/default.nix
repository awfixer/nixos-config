# Memory-tuned Quickshell: unused modules compiled out, GPU buffers dropped
# when windows hide, periodic QML/pixmap cache trim.
#
# Feature flags match what the ii shell actually imports (Wayland, Hyprland,
# screencopy, pipewire, mpris, pam, polkit, upower, notifications, tray,
# bluetooth, sockets). X11, i3, greetd, and Quickshell.Network are unused.
{
  lib,
  stdenv,
  quickshell,
}:
let
  system = stdenv.hostPlatform.system;
  upstream = quickshell.packages.${system}.default.override {
    withX11 = false;
    withI3 = false;
  };
in
upstream.unwrapped.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ./patches/0001-release-gpu-resources-on-hidden-windows.patch
    ./patches/0002-idle-trim-qml-and-pixmap-caches.patch
  ];
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    (lib.cmakeBool "X11" false)
    (lib.cmakeBool "I3" false)
    (lib.cmakeBool "I3_IPC" false)
    (lib.cmakeBool "SERVICE_GREETD" false)
    # ii talks to NetworkManager via nmcli (Quickshell.Io), not this module.
    (lib.cmakeBool "NETWORK" false)
  ];
})
