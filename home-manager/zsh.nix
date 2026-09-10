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
      . "$HOME/.local/bin/env"
      export PATH="/home/awfixer/.bun/install/global/~/.bun/bin:$PATH"
      export PATH="/home/awfixer/.bun/bin:$PATH"
      [ -f "$HOME/.local/state/quickshell/user/generated/terminal/sequences.txt" ] \
        && cat "$HOME/.local/state/quickshell/user/generated/terminal/sequences.txt"
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
        "zsh-interactive-cd"
        "zsh-navigation-tools"
        "zoxide"
      ];
    };

    # Useful aliases
    shellAliases = {
      scrub = "sudo rm -rf /tmp/ .local/share/direnv .var .cache .cargo .bun/install/cache .npm .mozilla **/target **/.direnv && clean && reboot";
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
      # tyyt — release binary via ~/.local/bin (see Super+Y in hyprland.nix)
      tyyt = "/home/awfixer/.local/bin/tyyt";
      # Pure flake — hardware is vendored under hosts/laptop (no --impure).
      # GC is a separate `clean` alias; do not thrash the store on every switch.
      # Do not pass --recreate-lock-file / --upgrade / --refresh: those re-resolve
      # every input from flake.nix URLs on each switch. Use `nfu` to update.
      nrs = "clean && sudo nixos-rebuild switch --flake '/home/awfixer/nixos-config#laptop' --fallback --verbose --no-reexec && sudo systemctl restart home-manager-awfixer.service";
      hm-act = "sudo systemctl restart home-manager-awfixer.service";
      nfu = "nix flake update";
      astro = "bun astro";
      ga = "git add";
      gc = "git commit -m";
      gp = "git push";
      gall = "git add && git commit -m 'update' && git push";
    };
  };
}
