{ config, ... }:

let
  # 1Password SSH agent — unlocks keys in the desktop app / CLI
  onePasswordAgent = "${config.home.homeDirectory}/.1password/agent.sock";

  # Public keys only (private material stays in 1Password).
  # Used with IdentitiesOnly so SSH does not offer every agent key in order.
  # Without this, "GitHub Auth Solved" (solvedgg) is accepted first and
  # awfixer private repos look like "Repository not found".
  githubAwfixerPub =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFy/OIaYvM76NowPoD9tfRNjEybQQEhsR1s6RUS85zNu github\n";
  githubSolvedPub =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFWLAU/ynapAk9ggusoq1GwyEIezpK69ZQ33QBgqDX9z GitHub Auth Solved\n";
in
{
  # Seed public key files for Host github.com identity selection
  home.file.".ssh/github.pub".text = githubAwfixerPub;
  home.file.".ssh/github-solved.pub".text = githubSolvedPub;

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

      # Default GitHub → awfixer account
      "github.com" = {
        identityAgent = onePasswordAgent;
        identitiesOnly = true;
        identityFile = "${config.home.homeDirectory}/.ssh/github.pub";
      };

      # Second GitHub account: git@github.com-solved:org/repo.git
      "github.com-solved" = {
        hostname = "github.com";
        identityAgent = onePasswordAgent;
        identitiesOnly = true;
        identityFile = "${config.home.homeDirectory}/.ssh/github-solved.pub";
      };
    };
  };
}
