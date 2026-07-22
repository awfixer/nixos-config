{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;
  # Default until waypaper --restore / picker chooses something else.
  defaultWallpaper = "${home}/Pictures/Wallpapers/JPEG/Cyberpunk.jpeg";
in
{
  home.packages = [ pkgs.waypaper ];

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;

      preload = [ defaultWallpaper ];

      wallpaper = [
        {
          monitor = "";
          path = defaultWallpaper;
          fit_mode = "cover";
        }
      ];
    };
  };

  # Waypaper GUI → hyprpaper backend; folder matches existing library.
  xdg.configFile."waypaper/config.ini".text = ''
    [Settings]
    language = en
    folder = ${home}/Pictures/Wallpapers
    wallpaper = ${defaultWallpaper}
    backend = hyprpaper
    monitors = All
    fill = fill
    sort = name
    color = #ffffff
    subfolders = True
    show_hidden = False
    show_gifs_only = False
    post_command =
    number_of_columns = 3
    swww_transition_type = any
    swww_transition_step = 90
    swww_transition_angle = 0
    swww_transition_duration = 2
    swww_transition_fps = 60
    use_xdg_state = True
  '';
}
