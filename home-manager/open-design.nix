{ pkgs, ... }:

{
  # System units in modules/open-design.nix serve the UI on loopback :80.
  xdg.desktopEntries.open-design = {
    name = "Open Design";
    comment = "Local Open Design studio";
    exec = "${pkgs.helium-browser}/bin/helium http://opendesign.local";
    terminal = false;
    categories = [
      "Graphics"
      "Development"
    ];
    startupNotify = true;
  };
}
