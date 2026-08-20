{ config, ... }:

let
  # 1Password SSH agent — unlocks keys in the desktop app / CLI
  onePasswordAgent = "${config.home.homeDirectory}/.1password/agent.sock";
in
{
  # SSH_AUTH_SOCK must point to 1Password agent for:
  #   - SSH agent forwarding (ForwardAgent picks up $SSH_AUTH_SOCK)
  #   - Non-SSH programs that read the socket directly
  # This must match the IdentityAgent paths set in settings below.
  home.sessionVariables = {
    SSH_AUTH_SOCK = onePasswordAgent;
  };

  programs.ssh = {
    enable = true;
    # Defaults will be removed from home-manager; pin them explicitly.
    enableDefaultConfig = false;
    settings = {
      # Former home-manager default Host * values (kept intentionally).
      # IdentityAgent here so every SSH connection uses 1Password's agent
      # and every agent key, instead of IdentitiesOnly + a single IdentityFile.
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
        IdentityAgent = onePasswordAgent;
      };

      # Only remote host: ssh mine  ≡  ssh awfixer@100.111.226.66
      "mine" = {
        HostName = "100.111.226.66";
        User = "awfixer";
        ForwardAgent = true;
        IdentityAgent = onePasswordAgent;
      };

      # Existing remotes using git@github.com-solved:org/repo.git
      "github.com-solved" = {
        HostName = "github.com";
        IdentityAgent = onePasswordAgent;
      };
    };
  };
}
