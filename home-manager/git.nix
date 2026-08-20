{ config, lib, pkgs, ... }:

let
  onePasswordAgent = "${config.home.homeDirectory}/.1password/agent.sock";

  # Public halves of the 1Password SSH keys. Private keys stay in the agent.
  # Change `activeAccount` and rebuild (`hm-act` / `nrs`) to hot-swap GitHub login + signing together.
  accounts = {
    awfixer = {
      name = "awfixer";
      email = "github@awfixer.me";
      # 1Password item "github" — SSH login
      loginKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFy/OIaYvM76NowPoD9tfRNjEybQQEhsR1s6RUS85zNu";
      # 1Password item "git-signing" — ssh-sign
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgScIZg527PNvtCt84Zf0AlFTgJ6A08BE3X7wwvPJIR";
    };
    solved = {
      name = "solvedgg";
      email = "contact@solved.gg";
      # 1Password item "GitHub Auth Solved" — SSH login
      loginKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFWLAU/ynapAk9ggusoq1GwyEIezpK69ZQ33QBgqDX9z";
      # 1Password item "GitHub Signing Solved" — ssh-sign
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVNrftO0yMosEXTrDmEamuBMhCwFr9j1N9YnD3cg9PA";
    };
  };

  activeAccount = "solved";
  acct = accounts.${activeAccount};

  loginPubs = lib.mapAttrs (
    name: a: pkgs.writeText "github-${name}-login.pub" "${a.loginKey} github-${name}\n"
  ) accounts;
  loginPub = loginPubs.${activeAccount};

  githubHost = pub: {
    HostName = "github.com";
    User = "git";
    IdentityAgent = onePasswordAgent;
    IdentitiesOnly = "yes";
    IdentityFile = toString pub;
  };
in
{
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = acct.name;
      user.email = acct.email;
      core.sshCommand = "${pkgs.openssh}/bin/ssh -o IdentityAgent=${onePasswordAgent}";
    };
    signing = {
      format = "ssh";
      key = acct.signingKey;
      signer = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      signByDefault = true;
    };
  };

  # github.com follows `activeAccount`. Aliases keep a specific login even if the default flips:
  #   git@github.com-awfixer:org/repo.git
  #   git@github.com-solved:org/repo.git
  programs.ssh.settings = {
    "github.com" = githubHost loginPub;
    "github.com-awfixer" = githubHost loginPubs.awfixer;
    "github.com-solved" = githubHost loginPubs.solved;
  };
}
