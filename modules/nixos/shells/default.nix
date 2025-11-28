# Shell Configuration Module
# System-wide shell configurations and integrations
# NixOS shell configuration: https://nixos.org/manual/nixos/stable/#sec-shell
{ ... }:
{
  imports = [
    ./zsh.nix # Zsh shell configuration and plugins
    #./fish.nix     # Fish shell configuration (currently disabled)
    #./bash.nix     # Bash shell configuration (currently disabled)
    #./nushell.nix  # Nushell configuration (currently disabled)
  ];
}
