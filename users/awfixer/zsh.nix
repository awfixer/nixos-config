{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BAT_THEME = "catppuccin-mocha";
      NVM_DIR = "$HOME/.config/nvm";
    };
    sessionPath = [
      "/etc/profiles/per-user/awfixer/bin"
      "/var/lib/flatpak/exports/bin"
      "/run/wrappers/bin"
      "$HOME/.local/bin"
      "$HOME/bin"
      "$HOME/.safe-chain/bin"
      "$HOME/.local/state/nix/profile/bin"
      "$HOME/go/bin"
      "$HOME/.opencode/bin"
      "$HOME/.bun/bin"
      "$HOME/.config/.foundry/bin"
      "$HOME/.nix-profile/bin"
      "$HOME/.local/share/pnpm"
      "$HOME/.cache/.bun/bin"
    ];
    shellAliases = (import ./aliases.nix) // { };
    ohMyZsh = {
      enable = true;
      initExtraFirst = ''
        # NVM setup ───────────────────────────────────────────────────────────────
        export NVM_DIR="$HOME/.config/nvm"

        # Load nvm if it exists (safe & idempotent)
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Optional: nvm bash completions (works in zsh too)
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      '';
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
