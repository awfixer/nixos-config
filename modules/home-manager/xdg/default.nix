{ lib
, pkgs
, ...
}:
with lib;
let
  defaultApplications = {
    browser = "firefox.desktop";
    videoPlayer = "clapper.desktop";
    textEditor = "zeditor.desktop";
    fileManager = "nautilus.desktop";
  };
in
{
  xdg = {
    enable = true;
    userDirs = {
      createDirectories = true;
    };
    mimeApps =
      let
        browserMimeTypes = (
          [ "text/html" ]
          ++ lib.lists.forEach [ "http" "https" "about" "unknown" ] (x: "x-scheme-handler/" + x)  # URL schemes
        );
        videoMimeTypes = [
          "video/x-matroska"
          "video/mp4"
          "video/webm"
          "video/*"
        ];
        documentTypes = [ "application/pdf" ];
        textTypes = [
          "application/json"
          "text/plain"
          "text/markdown"
        ];
        folderTypes = [ "inode/directory" ];
      in
      {
        enable = true;
        defaultApplications = mkMerge [
          (lib.attrsets.genAttrs videoMimeTypes (name: defaultApplications.videoPlayer))
          (lib.attrsets.genAttrs browserMimeTypes (name: defaultApplications.browser))
          (lib.attrsets.genAttrs documentTypes (name: defaultApplications.browser))
          (lib.attrsets.genAttrs textTypes (name: defaultApplications.textEditor))
          (lib.attrsets.genAttrs folderTypes (name: defaultApplications.fileManager))
        ];
      };
  };
}
