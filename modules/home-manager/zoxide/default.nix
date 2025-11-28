{ ... }:
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    options = [
      "--hook pwd"
    ];
  };
}
