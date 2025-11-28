{ pkgs
, lib
, config
, nixosConfig ? { }
, ...
}:
with lib;
{
  home.packages = with pkgs; [
    git-crypt
    git-lfs
    git
    glab
    doctl
    gh
    nix-prefetch-github
    nixpkgs-fmt
    statix
    pre-commit
  ];

  programs.git = {
    userName = "awfixer"; # Git username for commits
    userEmail = "git@awfixer.me"; # Git email for commits
    enable = true; # Enable Git with Home Manager

    # Delta diff viewer configuration
    # Provides syntax highlighting and better diff formatting
    delta = {
      enable = true; # Enable delta as the default pager
      options = {
        side-by-side = true; # Show diffs side-by-side
        line-numbers = true; # Display line numbers
        dark = true; # Use dark theme
      };
    };

    # Git Large File Storage (LFS) support
    # For handling large files efficiently in Git repositories
    lfs.enable = true;

    # Convenient Git command aliases
    aliases = {
      st = "status"; # Quick status check
      p = "push"; # Quick push
      c = "commit"; # Quick commit
      a = "add"; # Quick add
    };

    # Global gitignore patterns
    # Files matching these patterns will be ignored in all repositories
    ignores = [
      "*~" # Temporary files
      "*.swp" # Vim swap files
    ];

    # Additional Git configuration
    extraConfig = {
      merge.conflictstyle = "diff3"; # Show original content in merge conflicts
      core.editor = "nvim"; # Use Neovim as the default editor
      init.defaultBranch = "main"; # Use 'main' as default branch name

      # GPG/SSH signing configuration
      gpg.format = "ssh"; # Use SSH keys for signing instead of GPG

      # 1Password SSH agent integration for commit signing
      # Conditionally sets the SSH signing program if 1Password is configured
      gpg."ssh".program = lib.mkIf
        (
          nixosConfig != { }
          && nixosConfig.programs._1password-gui.enable
          && nixosConfig.programs._1password-gui.sshAgent
        ) "${nixosConfig.programs._1password-gui.package}/bin/op-ssh-sign";

      commit.gpgsign = true; # Automatically sign all commits

      # SSH public key for commit signing
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgScIZg527PNvtCt84Zf0AlFTgJ6A08BE3X7wwvPJIR";

      # Convenience settings
      push.autoSetupRemote = true; # Automatically set up remote tracking for new branches
      merge.tool = "meld"; # Use Meld as the merge tool for conflict resolution
    };
  };
}
