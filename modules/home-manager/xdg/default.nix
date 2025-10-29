# XDG Configuration - Desktop Integration and Default Applications
# Configures XDG Base Directory specification and default applications for file types
# XDG Base Directory spec: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# MIME types specification: https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html
# Home Manager XDG options: https://nix-community.github.io/home-manager/options.xhtml#opt-xdg.enable
{
  lib,
  pkgs,
  ...
}:
with lib;
let
  # Default applications for various file types
  defaultApplications = {
    browser = "zen-browser.desktop";      # Zen Browser for web content
    videoPlayer = "clapper.desktop";      # Clapper for video files
    #audioPlayer = "amberol.desktop";     # Audio player (currently disabled)
    textEditor = "zeditor.desktop";       # Zed for text editing
    fileManager = "nautilus.desktop";     # GNOME Files for directory browsing
  };
in
{
  xdg = {
    enable = true;                        # Enable XDG configuration
    
    # User directories (Documents, Downloads, etc.)
    userDirs = {
      createDirectories = true;           # Automatically create XDG user directories
    };
    
    # MIME type associations - determines which application opens which file types
    mimeApps =
      let
        # Define MIME type categories for easier management
        browserMimeTypes = (
          [ "text/html" ]                   # HTML files
          ++ lib.lists.forEach [ "http" "https" "about" "unknown" ] (x: "x-scheme-handler/" + x)  # URL schemes
        );
        videoMimeTypes = [
          "video/x-matroska"               # MKV files
          "video/mp4"                      # MP4 files
          "video/webm"                     # WebM files
          "video/*"                        # All video types
        ];
        documentTypes = [ "application/pdf" ];  # PDF documents
        textTypes = [
          "application/json"               # JSON files
          "text/plain"                     # Plain text files
          "text/markdown"                  # Markdown files
        ];
        folderTypes = [ "inode/directory" ];   # Directory/folder types
      in
      {
        enable = true;                    # Enable MIME type associations
        
        # Generate default application mappings for each MIME type category
        defaultApplications = mkMerge [
          (lib.attrsets.genAttrs videoMimeTypes (name: defaultApplications.videoPlayer))
          #(lib.attrsets.genAttrs audioMimeTypes (name: defaultApplications.audioPlayer))
          (lib.attrsets.genAttrs browserMimeTypes (name: defaultApplications.browser))
          (lib.attrsets.genAttrs documentTypes (name: defaultApplications.browser))    # Open PDFs in browser
          (lib.attrsets.genAttrs textTypes (name: defaultApplications.textEditor))
          (lib.attrsets.genAttrs folderTypes (name: defaultApplications.fileManager))
        ];
      };
  };
}
