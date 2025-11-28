{ ... }:

{
  services.flatpak = {
    enable = true;
    update.auto.enable = true;
    uninstallUnmanaged = true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
      { name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"; }
    ];
    packages = [
      "com.fastmail.Fastmail"
      "io.github.brunofin.Cohesion"
      "com.ranfdev.Notify"
      "io.github.pieterdd.RcloneShuttle"
      "com.github.unrud.VideoDownloader"
    ];
    overrides.global = {
      Context.sockets = [ "wayland" "x11" ];
    };
  };
}
