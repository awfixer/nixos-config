{ ... }:
{
  programs.nixcord = {
    enable = true;
    discord = {
      vencord.enable = true;
    };
    config = {
      themeLinks = [
        "https://raw.githubusercontent.com/awfixer/awfixer/refs/heads/main/midnight.theme.css"
      ];
      frameless = true;
      plugins = {
        crashHandler = {
          enable = true;
          attemptToPreventCrashes = true;
        };
        ctrlEnterSend = {
          enable = true;
          submitRule = "shift+enter";
        };
        dearrow = {
          enable = true;
          dearrowByDefault = true;
          hideButton = true;
          replaceElements = "everything";
        };
        experiments = {
          enable = true;
        };
        forceOwnerCrown.enable = true;
        friendInvites.enable = true;
        friendsSince.enable = true;
        gameActivityToggle.enable = true;
        spotifyShareCommands.enable = true;
        memberCount = {
          enable = true;
          memberList = true;
          toolTip = true;
        };
        messageTags = {
          enable = true;
          clyde = true;
        };
        moreCommands.enable = true;
        platformIndicators = {
          enable = true;
          badges = true;
          lists = false;
          messages = false;
          colorMobileIndicator = false;
        };
        relationshipNotifier = {
          enable = true;
          friendRequestCancels = true;
          friends = true;
          groups = true;
          notices = true;
          offlineRemovals = true;
          servers = true;
        };
        serverInfo.enable = true;
        serverListIndicators = {
          enable = true;
          mode = "both";
        };
        shikiCodeblocks = {
          enable = true;
          theme = "https://raw.githubusercontent.com/shikijs/shiki/0b28ad8ccfbf2615f2d9d38ea8255416b8ac3043/packages/shiki/themes/dark-plus.json";
          useDevIcon = "COLOR";
        };
        showHiddenThings = {
          enable = true;
          disableDiscoveryFilters = true;
          showInvitesPaused = true;
          showModView = true;
          showTimeouts = true;
        };
        showTimeoutDuration = {
          enable = true;
          displayStyle = "ssalggnikool";
        };
        spotifyControls = {
          enable = true;
          useSpotifyUris = true;
        };
        plainFolderIcon.enable = true;
        silentTyping = {
          enable = true;
          isEnabled = true;
          contextMenu = true;
          showIcon = true;
        };
      };
    };
  };
}
