# Financial and Cryptocurrency Tools
# Tools for financial tracking, portfolio management, and cryptocurrency monitoring
# Financial tools overview: https://github.com/jdorfman/awesome-finance
{ pkgs, ... }:

let
  # Financial and cryptocurrency management tools
  money = with pkgs; [
    # Cryptocurrency Monitoring
    cointop # Terminal-based cryptocurrency tracker - https://cointop.sh/

    # Portfolio Management
    ghostfolio # Privacy-focused portfolio tracker - https://ghostfol.io/
  ];
in

{
  # Install all financial packages to user environment
  home.packages = builtins.concatLists [ money ];
}
