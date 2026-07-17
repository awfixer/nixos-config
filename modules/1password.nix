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

  # Process names as seen in /proc/<pid>/comm (and custom_allowed_browsers).
  # Helium's binary is `helium`, not `helium-browser`.
  allowedBrowsers = ''
    helium
    brave
  '';
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
  # (chrome, chromium, brave, vivaldi, …). It never writes to Helium's
  # ~/.config/net.imput.helium/NativeMessagingHosts/. Seed it for every user.
  system.userActivationScripts.onepasswordHeliumNmh = {
    text = ''
      nmh_dir="$HOME/.config/net.imput.helium/NativeMessagingHosts"
      mkdir -p "$nmh_dir"
      printf '%s\n' '${nmhManifest}' > "$nmh_dir/com.1password.1password.json"
    '';
  };
}
