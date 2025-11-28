{ ... }:
{
  programs.fzf = {
    enable = true;
    defaultOptions = [
      "--walker-skip=.git,.direnv,node_modules,.devbox,.claude"
    ];
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    historyWidgetOptions = [ "--sort" "--exact" ];
  };
}
