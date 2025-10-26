{
  pkgs,
  lib,
  config,
  nixosConfig ? { },
  ...
}:
with lib;
{
  home.packages = [ pkgs.git-crypt ];
  programs.git = {
    userName = "awfixer";
    userEmail = "github@awfixer.me";
    enable = true;
    delta = {
      enable = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        dark = true;
      };
    };
    lfs.enable = true;
    aliases = {
      st = "status";
      p = "push";
      c = "commit";
      a = "add";
    };

    ignores = [
      "*~"
      "*.swp"
    ];
    extraConfig = {
      merge.conflictstyle = "diff3";
      core.editor = "nvim";
      init.defaultBranch = "main";
      gpg.format = "ssh";
      gpg."ssh".program = lib.mkIf (
        nixosConfig != { }
        && nixosConfig.programs._1password-gui.enable
        && nixosConfig.programs._1password-gui.sshAgent
      ) "${nixosConfig.programs._1password-gui.package}/bin/op-ssh-sign";
      commit.gpgsign = true;
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgScIZg527PNvtCt84Zf0AlFTgJ6A08BE3X7wwvPJIR";
      push.autoSetupRemote = true;
      merge.tool = "meld";
    };
  };
}
