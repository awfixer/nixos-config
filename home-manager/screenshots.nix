{
  config,
  pkgs,
  ...
}:

let
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";

  # Annotate → clipboard + file under ~/Pictures/Screenshots
  sattyCmd = ''
    satty \
      --filename - \
      --fullscreen \
      --output-filename "${screenshotDir}/satty-%Y%m%d-%H%M%S.png" \
      --early-exit all \
      --copy-command wl-copy \
      --actions-on-enter save-to-clipboard,save-to-file,exit \
      --actions-on-escape exit \
      --font-family "JetBrains Mono"
  '';

  screenshot-region = pkgs.writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = with pkgs; [
      grim
      slurp
      satty
      wl-clipboard
      libnotify
      coreutils
    ];
    text = ''
      set -euo pipefail
      mkdir -p "${screenshotDir}"
      geom="$(slurp)" || exit 0
      grim -g "$geom" - | ${sattyCmd}
    '';
  };

  screenshot-full = pkgs.writeShellApplication {
    name = "screenshot-full";
    runtimeInputs = with pkgs; [
      grim
      satty
      wl-clipboard
      libnotify
      coreutils
    ];
    text = ''
      set -euo pipefail
      mkdir -p "${screenshotDir}"
      grim - | ${sattyCmd}
    '';
  };

  screenshot-window = pkgs.writeShellApplication {
    name = "screenshot-window";
    runtimeInputs = with pkgs; [
      grim
      satty
      wl-clipboard
      libnotify
      coreutils
      jq
      hyprland
    ];
    text = ''
      set -euo pipefail
      mkdir -p "${screenshotDir}"
      geom="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
      if [[ -z "$geom" || "$geom" == "null,null nullxnull" ]]; then
        notify-send "Screenshot" "No active window"
        exit 1
      fi
      grim -g "$geom" - | ${sattyCmd}
    '';
  };
in
{
  home.packages = [
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    screenshot-region
    screenshot-full
    screenshot-window
  ];

  # Sensible satty defaults when launched without our wrappers
  xdg.configFile."satty/config.toml".text = ''
    [general]
    fullscreen = true
    early-exit = true
    copy-command = "wl-copy"
    output-filename = "${screenshotDir}/satty-%Y%m%d-%H%M%S.png"
    actions-on-enter = ["save-to-clipboard", "save-to-file", "exit"]
    actions-on-escape = ["exit"]
    annotation-size-factor = 1
    save-after-copy = false
    default-hide-toolbars = false

    [font]
    family = "JetBrains Mono"
  '';
}
