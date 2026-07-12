{ config, ... }:

let
  # 1Password SSH agent — unlocks keys in the desktop app / CLI
  onePasswordAgent = "${config.home.homeDirectory}/.1password/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # Only remote host: ssh mine  ≡  ssh awfixer@100.111.226.66
      "mine" = {
        hostname = "100.111.226.66";
        user = "awfixer";
        forwardAgent = true;
        identityAgent = onePasswordAgent;
      };
    };
  };
}
