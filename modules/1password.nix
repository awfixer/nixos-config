{ config, lib, pkgs, ... }:

let
  # Official 1Password Chrome-extension IDs (stable + betas) that BrowserSupport accepts.
  allowedOrigins = [
    "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/"
    "chrome-extension://bkpbhnjcbehoklfkljkkbbmipaphipgl/"
    "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/"
    "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/"
    "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/"
    "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
  ];

  # Must use the setgid security wrapper — the raw store binary is rejected.
  browserSupportPath = "/run/wrappers/bin/1Password-BrowserSupport";

  nmhManifest = builtins.toJSON {
    name = "com.1password.1password";
    description = "1Password BrowserSupport";
    path = browserSupportPath;
    type = "stdio";
    allowed_origins = allowedOrigins;
  };

  # Executable basenames for 1Password BrowserSupport allow-list
  # (/etc/1password/custom_allowed_browsers). Must match the on-disk binary
  # name (basename of /proc/<pid>/exe), not necessarily /proc/comm.
  # Helium → helium; Orion GTK flatpak command → oriongtk.
  # Note: Orion renames its process comm to "main"; allow-list still uses
  # the executable basename `oriongtk`.
  allowedBrowsers = ''
    helium
    oriongtk
    brave
  '';

  # Config dirs where Chromium-style Native Messaging Hosts are read.
  # Relative to $HOME/.config/ unless absolute (see seed script).
  # Orion GTK beta uses the Flatpak-style tree even when installed natively:
  #   ~/.var/app/com.kagi.OrionGtk/...
  nmhConfigDirs = [
    # relative → $HOME/.config/<dir>/NativeMessagingHosts
    "net.imput.helium"
    "com.kagi.OrionGtk"
    "oriongtk"
  ];

  # Absolute-under-home paths (not under .config).
  nmhHomeRelativeDirs = [
    ".var/app/com.kagi.OrionGtk/config"
    ".var/app/com.kagi.OrionGtk/config/chromium"
  ];
in
{
  # Desktop app + CLI (installs setgid 1Password-BrowserSupport wrapper).
  programs._1password = {
    enable = true;
    package = pkgs._1password-cli;
  };

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "awfixer" ];
  };

  environment.etc = {
    # 1Password only trusts browsers on its built-in list, or entries here.
    # Docs: https://support.1password.com/additional-browsers/
    # Own this path exclusively (chromium.nix used to also set it).
    "1password/custom_allowed_browsers" = lib.mkForce {
      text = allowedBrowsers;
      # Executable bit is conventional for this file on 1Password's docs/examples.
      mode = "0755";
    };

    # Helium (and other Chromium forks) can read system NMH from here.
    # packages/helium binds /etc/chromium into its environment.
    "chromium/native-messaging-hosts/com.1password.1password.json".text = nmhManifest;
  };

  # 1Password's NMH installer only knows a hard-coded list of config dirs
  # (chrome, chromium, brave, vivaldi, …). It never writes to Helium's or
  # Orion's config trees. Seed NativeMessagingHosts for every user.
  system.userActivationScripts.onepasswordCustomBrowserNmh = {
    text = ''
      ${lib.concatMapStrings (dir: ''
        nmh_dir="$HOME/.config/${dir}/NativeMessagingHosts"
        mkdir -p "$nmh_dir"
        printf '%s\n' '${nmhManifest}' > "$nmh_dir/com.1password.1password.json"
      '') nmhConfigDirs}
      ${lib.concatMapStrings (dir: ''
        nmh_dir="$HOME/${dir}/NativeMessagingHosts"
        mkdir -p "$nmh_dir"
        printf '%s\n' '${nmhManifest}' > "$nmh_dir/com.1password.1password.json"
      '') nmhHomeRelativeDirs}
    '';
  };
}
