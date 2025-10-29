# Bat Configuration - Enhanced Cat with Syntax Highlighting
# A cat clone with wings - syntax highlighting and Git integration
# Bat documentation: https://github.com/sharkdp/bat
# Home Manager bat options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.bat.enable
{ pkgs, ... }:
{
  programs.bat = {
    enable = true;              # Enable bat as enhanced cat replacement
    config = { 
      # Configuration options can be added here
      # Examples:
      # theme = "TwoDark";
      # pager = "less -FR";
      # style = "numbers,changes,header";
    };
    extraPackages = [ 
      # Additional syntax highlighting packages can be added here
      # Examples: bat-extras packages for additional functionality
    ];
    themes = { 
      # Custom themes can be defined here
      # Themes are written in Sublime Text .tmTheme format
    };
  };
}
