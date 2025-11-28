{ ... }:
{
  programs.nushell = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = (import ./aliases.nix) // { };
  };
}
