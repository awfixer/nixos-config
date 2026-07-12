{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true; # zsh-users/zsh-autosuggestions
    syntaxHighlighting.enable = true; # zsh-users/zsh-syntax-highlighting
    historySubstringSearch.enable = true; # zsh-users/zsh-history-substring-search

    # Preserve existing sourced env
    initContent = ''
      . "$HOME/.cargo/bin/env"
      . "$HOME/.bun/bin/env"
      . "$HOME/.local/bin/env"
      eval "$(atuin init zsh)"
    '';

    # History configuration
    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
    };

    # Shell options
    setOptions = [
      "AUTO_CD"
      "AUTO_LIST"
      "AUTO_MENU"
      "AUTO_PARAM_SLASH"
      "COMPLETE_IN_WORD"
      "CORRECT"
      "EXTENDED_GLOB"
      "GLOB_STAR_SHORT"
    ];

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "1password"
        "git"
        "sudo"
        "copyfile"
        "dirhistory"
        "history"
        "zsh-interactive-cd"
        "zsh-navigation-tools"
        "zoxide"
      ];
    };

    # Useful aliases
    shellAliases = {
      clone = "git clone --depth=1";
      clean = "sudo nix-collect-garbage -d";
      ll = "ls -lah";
      c = "clear";
      cd = "z";
      la = "ls -A";
      l = "ls -F";
      grep = "grep --color=auto";
      df = "df -h";
      free = "free -h";
      nrs = "clean && sudo nixos-rebuild switch --flake '/home/awfixer/nixos-config#nixos' --impure && sudo systemctl restart home-manager-awfixer.service";
      hm-act = "sudo systemctl restart home-manager-awfixer.service";
      nfu = "nix flake update";
      ga = "git add";
      gc = "git commit -m";
      gp = "git push";
      gall = "git add && git commit -m 'update' && git push";
    };
  };
}
