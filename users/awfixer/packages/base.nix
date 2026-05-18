{ inputs, pkgs, ... }:

let
  base = with pkgs; [
    #inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    obsidian
    clapper
    clapper-enhancers
    nautilus
    kiro-cli
    graphite-cli
    cursor-cli
    vesktop
    ghostty
    gh
  ];
in

{
  home.packages = builtins.concatLists [ base ];
}
