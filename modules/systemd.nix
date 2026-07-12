{ config, lib, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /etc/atuin 0755 root root -"
  ];
}
