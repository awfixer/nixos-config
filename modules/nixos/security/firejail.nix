{pkgs, ... }:

{
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      chromium-browser = {
      executable = "${pkgs.chromium}/bin/chromium-browser";
      profile = "${pkgs.firejail}/etc/firejail/chromium-browser.profile";
      extraArgs = [
        "--blacklist=/etc/ld-nix.so.preload"
        ];
      };
      chromium = {
      executable = "${pkgs.chromium}/bin/chromium";
      profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
      extraArgs = [
        "--blacklist=/etc/ld-nix.so.preload"
        ];
      };
      firefox = {
            executable = "${pkgs.firefox}/bin/librewolf";
            profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
            extraArgs = [
              # Required for U2F USB stick
              "--ignore=private-dev"
              # Enforce dark mode
              "--env=GTK_THEME=Adwaita:dark"
              # Enable system notifications
              "--dbus-user.talk=org.freedesktop.Notifications"
            ];
          };
    };
  };
}
