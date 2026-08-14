{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    zoxide
    fzf
    jq
    wl-clipboard
    brightnessctl
    adwaita-icon-theme
    noto-fonts
    nerd-fonts.jetbrains-mono
    libnotify
    # nm-applet is optional; waybar already shows network. Keep CLI control via nmcli.
    networkmanagerapplet # nm-connection-editor for Waybar network on-click

    # Waybar / SwayNC GNOME-style helpers (attrs via mcp-nixos unstable)
    gnome-calendar # clock on-click
    gnome-power-manager # gnome-power-statistics for battery details
    mission-center # battery right-click system monitor
    pavucontrol # volume mixer
    playerctl # mpris + playerctld
    wlogout # session exit menu from SwayNC buttons-grid
    wireplumber # wpctl for volume scroll on Waybar

    # On-demand only (not session daemons)
    # vesktop → programs.vesktop in vesktop.nix (PipeWire screenshare wrapper)
    libreoffice-fresh
    onlyoffice-desktopeditors
    ente-auth # E2E encrypted 2FA codes + cloud backup
  ];

}


