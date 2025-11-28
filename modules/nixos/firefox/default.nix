{ pkgs, ... }:

let
  lock = val: { Value = val; Status = "locked"; };
in
{
  nixpkgs.overlays = [
    (self: super: {
      betterfox = super.callPackage (import (builtins.fetchTarball {
        url    = "https://github.com/yokoffing/Betterfox/archive/main.tar.gz";
        sha256 = "sha256-1hlqs1qqrfnhc6fax9dgnb9hihj94p49yrl18skl96y05ac214di"; # replace!
      })) {};
    })
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    policies = {
      DisableTelemetry                     = true;
      DisableFirefoxStudies                = true;
      DisablePocket                        = true;
      DisableFirefoxAccounts               = true;
      DisableAccounts                      = true;
      DisableFirefoxScreenshots            = true;
      OverrideFirstRunPage                 = "";
      OverridePostUpdatePage               = "";
      DontCheckDefaultBrowser              = true;

      EnableTrackingProtection = {
        Value        = true;
        Locked       = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisplayBookmarksToolbar = "never";   # still a policy key
      DisplayMenuBar          = "never";
      SearchBar               = "unified";
      betterfox = {
        enable = true;
        version = "144";
        profiles.example-profile = {
          enableAllSections = true;
          settings = {
            fastfox.enable = true;
            peskyfox = {
              enable      = true;
              mozilla-ui.enable = false;
            };
            securefox = {
              enable = true;
              tracking-protection."browser.download.start_downloads_in_tmp_dir".value = true;
            };
          };
        };
      };
      ExtensionSettings = {
        # "*".installation_mode = "blocked";   # block everything else

        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
          private_browsing = true;
        };

        # Privacy Badger
        "{jid1-MnnxcxisBPnSXQ@jetpack}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
          private_browsing = true;
        };

        # 1Password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
        };

        # Port Authority
        "{6c00218c-707a-4977-84cf-36df1cef310f}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/file/4481055/port_authority-2.2.0.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
        };

        # Darkreader
        "{addon@darkreader.org}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };

        # CanvasBlocker
        "CanvasBlocker@kkapsner.de" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/latest/canvasblocker/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
          private_browsing = true;
        };

        # Tampermonkey
        "{e6b6f030-9b3c-4c0b-8c2d-3b2b5e5f5e5f}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
          installation_mode = "force_installed";
        };

        # Mergify (example – replace with real GUID if you use it)
        "{d1b33d6a57c463f0daef4abfb625edddd1c2d5d9@mergify.com}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/file/4571024/mergify-1.0.30.xpi";
          installation_mode = "force_installed";
        };

        # GitHub Web IDE
        "{bbda042b-c350-4e85-8d81-bda0d6fbda81}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/file/4501255/github_web_ide-2.0.11.xpi";
          installation_mode = "force_installed";
        };

        # JustDeleteMe
        "{6f54ad3f-042f-408f-8f06-ab631fe1a64f}" = {
          install_url      = "https://addons.mozilla.org/firefox/downloads/file/4525473/justdeleteme-1.6.0.xpi";
          installation_mode = "force_installed";
        };
      };
      Preferences = {
        "browser.contentblocking.category"                         = lock "strict";
        "extensions.pocket.enabled"                               = lock false;
        "extensions.screenshots.disabled"                         = lock true;
        "browser.topsites.contile.enabled"                        = lock false;
        "browser.formfill.enable"                                 = lock false;
        "browser.search.suggest.enabled"                          = lock false;
        "browser.search.suggest.enabled.private"                  = lock false;
        "browser.urlbar.suggest.searches"                         = lock false;
        "browser.urlbar.showSearchSuggestionsFirst"               = lock false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
        "browser.newtabpage.activity-stream.feeds.snippets"       = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket"    = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited"   = lock false;
        "browser.newtabpage.activity-stream.showSponsored"        = lock false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
      };
    };
  };
}
