{
  # Manages ~/.config/user-dirs.dirs (matches the previous xdg-user-dirs-update output).
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "$HOME/Public";
    templates = "$HOME/Templates";
    videos = "$HOME/Videos";
    projects = "$HOME/Projects";
  };

  # No dedicated upstream option for ~/.config/user-dirs.locale.
  xdg.configFile."user-dirs.locale".text = "en_US";
}
