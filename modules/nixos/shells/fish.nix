{ ... }:
{
  programs.fish = {
    enable = true;
    shellAliases = (import ./aliases.nix).group // { };

    ohmyFish = {
      enabe = true;
      plugins = [ ];
      theme = "random";
    };
  };
}
