# System Fonts Configuration
# Configures system-wide fonts including Nerd Fonts and Noto fonts
# NixOS fonts: https://nixos.wiki/wiki/Fonts
# Font options: https://search.nixos.org/options?query=fonts
{ pkgs, lib, ... }:
{
  fonts = {
    # Enable font directory for applications to discover fonts
    fontDir.enable = true;

    # Install comprehensive font packages
    # Dynamically includes all available Nerd Fonts and Noto fonts
    packages =
      # Nerd Fonts - patched fonts with glyphs for development
      # https://www.nerdfonts.com/
      builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)

      # Noto Fonts - Google's font family supporting many languages
      # https://fonts.google.com/noto
      ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.noto-fonts);

    # Additional font configuration options:
    # fontconfig.enable = true;                    # Enable fontconfig (usually enabled by default)
    # fontconfig.antialias = true;                 # Enable font antialiasing
    # fontconfig.hinting.enable = true;            # Enable font hinting
    # fontconfig.subpixel.rgba = "rgb";            # Subpixel rendering
    # fontconfig.defaultFonts = {                  # Set default fonts
    #   serif = [ "Noto Serif" ];
    #   sansSerif = [ "Noto Sans" ];
    #   monospace = [ "Noto Sans Mono" ];
    # };
  };
}
