{ pkgs, ... }:

{
  # Use the home-manager package only — do not symlink the AppImage
  # *-extracted path into ~/.local/bin (that bypasses the FHS wrapper and
  # drops Wayland libs → XWayland → pixelated UI on scale 1.5).
  home.packages = [
    pkgs.buzz
  ];
}
