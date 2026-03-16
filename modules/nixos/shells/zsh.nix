{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = (import ./aliases.nix) // { };
    ohMyZsh = {
      enable = true;
      plugins = [
        "1password"
        "aliases"
        "bun"
        "colored-man-pages"
        "command-not-found"
        "cp"
        "docker"
        "docker-compose"
        "emotty"
        "gh"
        "git"
        "github"
        "gitignore"
        "git-extras"
        "golang"
        "history"
        "history-substring-search"
        "kubectl"
        "npm"
        "pip"
        "python"
        "rust"
        "safe-paste"
        "sudo"
        "systemd"
        "tugboat"
        "zoxide"
        "zsh-interactive-cd"
      ];
      theme = "random";
    };
  };
}
