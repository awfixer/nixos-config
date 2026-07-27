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

  # Git commit signing key — also exposed to SSH agent for auth on solved account.
  # Must have "Use with the 1Password SSH agent" enabled in the 1Password desktop app
  # to appear in `ssh-add -L` and be available through agent forwarding.
  githubSolvedSigningPub =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgScIZg527PNvtCt84Zf0AlFTgJ6A08BE3X7wwvPJIR GitHub Signing Solved\n";
in
{
  # Seed public key files for Host github.com identity selection
  home.file.".ssh/github.pub".text = githubAwfixerPub;
  home.file.".ssh/github-solved.pub".text = githubSolvedPub;
  home.file.".ssh/github-solved-signing.pub".text = githubSolvedSigningPub;

  # SSH_AUTH_SOCK must point to 1Password agent for:
  #   - SSH agent forwarding (ForwardAgent picks up $SSH_AUTH_SOCK)
  #   - Non-SSH programs that read the socket directly
  # This must match the IdentityAgent paths set in matchBlocks below.
  home.sessionVariables = {
    SSH_AUTH_SOCK = onePasswordAgent;
  };

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
        identityFile = [
          "${config.home.homeDirectory}/.ssh/github-solved.pub"
          "${config.home.homeDirectory}/.ssh/github-solved-signing.pub"
        ];
      };
    };
  };
}
