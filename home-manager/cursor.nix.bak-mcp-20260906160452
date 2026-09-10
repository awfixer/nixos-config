{ config, pkgs, lib, ... }:

let
  version = "3.17.8";
  # Commit from downloads.cursor.com production channel (api/download).
  commit = "2fdd31c9f33f7fbe501f2d57772dc5bf64b63621";
  cursorPackage = pkgs."code-cursor".overrideAttrs (_: rec {
    inherit version;
    src = pkgs.appimageTools.extract {
      pname = "cursor";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
        hash = "sha256-OI0gaN8FfRseAGw7u1GQhatA7HguyKsg7CUN8IprdAI=";
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
