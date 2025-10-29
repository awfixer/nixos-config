# Base Desktop Applications
# Essential applications for daily desktop use
# Package search: https://search.nixos.org/packages
{ pkgs, ... }:

let
  # Core desktop applications organized by category
  base = with pkgs; [
    # Terminal and Text Editors
    ghostty                      # GPU-accelerated terminal emulator - https://ghostty.org/
    obsidian                     # Knowledge management and note-taking - https://obsidian.md/
    zed-editor                   # High-performance code editor - https://zed.dev/
    
    # Communication and Messaging
    simplex-chat-desktop         # Private messaging app - https://simplex.chat/
    session-desktop              # Private messenger - https://getsession.org/
    telegram-desktop             # Telegram messaging client - https://telegram.org/
    signal-desktop               # Secure messaging - https://signal.org/
    slack                        # Team communication - https://slack.com/
    vesktop                      # Discord client with enhanced features - https://github.com/Vencord/Vesktop
    discord-rpc                  # Discord Rich Presence library
    
    # Discord Tools and Utilities
    discordchatexporter-cli      # Export Discord chat logs (CLI) - https://github.com/Tyrrrz/DiscordChatExporter
    discordchatexporter-desktop  # Export Discord chat logs (GUI)
    
    # File Sharing and Downloads
    qbittorrent-enhanced         # Enhanced BitTorrent client - https://github.com/c0re100/qBittorrent-Enhanced-Edition
    transmission-remote-gtk      # Transmission BitTorrent remote client - https://github.com/transmission-remote-gtk/transmission-remote-gtk
    
    # Media and Entertainment
    clapper                      # Modern media player for GNOME - https://rafostar.github.io/clapper/
    clapper-enhancers           # Additional media format support for Clapper
    youtube-music               # YouTube Music desktop app - https://th-ch.github.io/youtube-music/
    
    # Privacy and Security Tools
    protonvpn-gui              # Proton VPN client - https://protonvpn.com/
    protonmail-desktop         # Proton Mail desktop client - https://proton.me/mail
    proton-pass                # Proton password manager - https://proton.me/pass
    
    # Utilities
    android-backup-extractor   # Extract Android backup files - https://github.com/nelenkov/android-backup-extractor
  ];
in

{
  # Install all base packages to user environment
  home.packages = builtins.concatLists [ base ];
}
