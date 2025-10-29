# LazyGit Configuration - Terminal UI for Git Commands
# A simple terminal UI for git commands with keyboard shortcuts
# LazyGit documentation: https://github.com/jesseduffield/lazygit
# Home Manager lazygit options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.lazygit.enable
{ ... }:
{
  programs.lazygit = {
    enable = true;              # Enable lazygit terminal UI for Git
    settings = {
      git.overrideGpg = true;   # Allow lazygit to override GPG settings
      
      # Additional settings that can be configured:
      # gui.theme = "dark";           # Set UI theme
      # git.paging.colorArg = "always"; # Enable colored output
      # refresher.refreshInterval = 10; # Auto-refresh interval in seconds
    };
  };
  
  # Convenient shell alias for quick access
  home.shellAliases.lg = "lazygit";
}
