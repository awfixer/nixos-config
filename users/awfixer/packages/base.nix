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
    code-cursor
    clapper
    clapper-enhancers
    nautilus
    kiro
    kiro-cli
    antigravity
    windsurf
    opencode-claude-auth
    opencode-desktop
    claude-agent-acp
    claude-code
    claude-code-acp
    claude-usage-tracker
    claude-monitor
    claude-mergetool
    claude-code-router
    gemini-cli
    geminicommit
    graphite-cli
    cursor-cli
    codex
    codex-acp
    pi-coding-agent
    vesktop
    ghostty
    gh
  ];
in

{
  home.packages = builtins.concatLists [ base ];
}
