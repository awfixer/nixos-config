{ config, lib, pkgs, ... }:

{
  virtualisation = {
    docker = {
      #extraPackages = with pkgs; [ criu ];
      enable = true;
      #extraOptions = "";
    };
  };
}
