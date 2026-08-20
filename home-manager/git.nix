{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = "solvedgg";
      user.email = "contact@solved.gg";
      core = {
        sshCommand = "${pkgs.openssh}/bin/ssh -o IdentityAgent=${config.home.homeDirectory}/.1password/agent.sock";
      };
    };
    # SSH signing via 1Password SSH agent (GitHub Signing Solved)
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgScIZg527PNvtCt84Zf0AlFTgJ6A08BE3X7wwvPJIR";
      signer = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      signByDefault = true;
    };
  };
}
