# Zsh Shell Configuration - Enhanced Shell Experience
# Configure Zsh with Oh My Zsh framework, plugins, and enhancements
# Zsh documentation: http://zsh.sourceforge.net/Doc/
# Oh My Zsh: https://ohmyz.sh/
{ ... }:
{
  programs.zsh = {
    enable = true; # Enable Zsh system-wide
    enableCompletion = true; # Enable advanced tab completion
    autosuggestions.enable = true; # Enable command autosuggestions based on history
    syntaxHighlighting.enable = true; # Enable syntax highlighting for commands

    # Import shell aliases from aliases.nix
    shellAliases = (import ./aliases.nix) // { };

    # Oh My Zsh framework configuration
    ohMyZsh = {
      enable = true; # Enable Oh My Zsh framework

      # Oh My Zsh plugins for enhanced functionality
      # Plugin documentation: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
      plugins = [
        "emotty" # Random emoji in prompt
        "aliases" # Alias management and search
        "colored-man-pages" # Colorized man pages
        "command-not-found" # Suggest package installation for missing commands
        "cp" # Enhanced cp command with progress
        "github" # GitHub integration and shortcuts
        "gitignore" # Gitignore management
        "golang" # Go development shortcuts
        "systemd" # systemd integration and shortcuts
        "pip" # Python pip integration
        "python" # Python development shortcuts
        "tugboat" # DigitalOcean tugboat integration
        "git" # Git shortcuts and aliases
        "npm" # NPM shortcuts and completion
        "zoxide" # Zoxide smart directory jumping
        "1password" # 1Password CLI integration
        "docker" # Docker command completion and shortcuts
        "docker-compose" # Docker Compose integration
        "git-extras" # Additional git commands
        "sudo" # Smart sudo functionality
        "zsh-interactive-cd" # Interactive directory navigation
      ];

      theme = "random"; # Use random theme on each session
      # Popular themes: "robbyrussell", "agnoster", "powerlevel10k", "spaceship"
    };

    # Additional Zsh configuration options:
    # promptInit = "...";             # Custom prompt initialization
    # interactiveShellInit = "...";   # Commands to run in interactive shells
    # loginShellInit = "...";         # Commands to run in login shells
  };
}
