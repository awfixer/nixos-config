{ pkgs
, lib
, ...
}:
with lib;
{
  options.programs._1password-gui = {
    sshAgent = mkEnableOption "1Password SSH Agent" // {
      default = true;
    };
  };

  config = {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        package = pkgs._1password-gui;
        enable = true;
        polkitPolicyOwners = [ "awfixer" ];
      };
    };
    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          .zen-wrapped      # Zen browser (wrapped)
          zen              # Zen browser
          .zen             # Zen browser (dotfile)
          chromium         # Chromium browser
          .chromium        # Chromium (dotfile)
          brave            # Brave browser
          .brave           # Brave (dotfile)
          .chromium-wrapped # Chromium (wrapped)
          .brave-wrapped   # Brave (wrapped)
        '';
        mode = "0755";
      };
    };
  };
}
