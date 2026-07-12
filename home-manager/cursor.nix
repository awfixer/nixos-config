{ config, pkgs, lib, ... }:

let
  cursorPackage = pkgs."code-cursor".overrideAttrs (_: rec {
    version = "3.7.19";
    src = pkgs.appimageTools.extract {
      pname = "cursor";
      version = "3.7.19";
      src = pkgs.fetchurl {
        url = "https://downloads.cursor.com/production/80c653c2c3528e65016a0d304b54486084b470bb/linux/x64/Cursor-3.7.19-x86_64.AppImage";
        hash = "sha256-qlNQwaDqPL1/wsxwyUXPWvoeXuWoVahibnk0H0h6KZ4=";
      };
    };
    sourceRoot = "cursor-${version}-extracted/usr/share/cursor";
  });
in
{
  programs.cursor = {
    enable = true;
    package = cursorPackage.fhs;
    profiles.default.enableMcpIntegration = true;
    argvSettings = {
      "password-store" = "gnome-libsecret";
    };
  };

  programs.mcp = {
    enable = true;
    servers.nixos = {
      command = "uvx";
      args = [ "mcp-nixos" ];
    };
  };

  home.packages = [ pkgs.uv ];
}
