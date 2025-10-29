# FZF Configuration - Command-line Fuzzy Finder
# A command-line fuzzy finder for files, command history, processes, and more
# FZF documentation: https://github.com/junegunn/fzf
# Home Manager fzf options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fzf.enable
{ ... }:
{
  programs.fzf = {
    enable = true;                    # Enable fzf fuzzy finder
    
    # Default options applied to all fzf invocations
    defaultOptions = [
      "--walker-skip=.git,.direnv,node_modules"  # Skip common directories that should not be searched
    ];
    
    # Additional configuration options that can be enabled:
    # enableBashIntegration = true;    # Enable Bash integration (Ctrl+R for history, Ctrl+T for files)
    # enableZshIntegration = true;     # Enable Zsh integration
    # enableFishIntegration = true;    # Enable Fish integration
    # defaultCommand = "fd --type f";  # Use fd as the default command for file searching
    # fileWidgetCommand = "fd --type f"; # Command for file widget (Ctrl+T)
    # historyWidgetOptions = [ "--sort" "--exact" ]; # Options for history widget (Ctrl+R)
  };
}
