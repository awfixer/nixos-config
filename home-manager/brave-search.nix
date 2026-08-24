{ pkgs, ... }:

{
  home.packages = [
    # Minimal Brave Search window (packages/brave-search) — SUPER+D
    pkgs.brave-search
  ];
}
