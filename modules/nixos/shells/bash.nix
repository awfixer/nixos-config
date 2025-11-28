{ ... }:
{
  programs.bash = {
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = (import ./aliases.nix) // { };
  };
}
