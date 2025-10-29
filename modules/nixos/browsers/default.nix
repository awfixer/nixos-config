# Browser Configuration Module
# System-wide configurations for web browsers
# Browser security guide: https://nixos.wiki/wiki/Firefox
{ ... }:
{
  imports = [
    ./chromium        # Chromium browser configuration
    ./firefox         # Firefox browser configuration
    #./zen-browser    # Zen browser configuration (currently disabled)
  ];
}
