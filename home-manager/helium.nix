{ pkgs, lib, ... }:

{
  home.packages = [
    pkgs.helium-browser
  ];

  # Prefer Helium for CLI tools that honor $BROWSER
  home.sessionVariables.BROWSER = "helium";

  # Set Helium as the system default web browser (GNOME/XDG)

}
