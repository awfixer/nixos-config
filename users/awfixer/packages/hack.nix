{ pkgs, ... }:
let
  hack = with pkgs; [
    ghorg
    ghost
    wireshark-cli
    netcat
    angryipscanner
    nmap
    yara
    yaralyzer
    burpsuite
    hydra
    hashcat
    hashcat-utils
    metasploit
  ];
in
{
  home.packages = builtins.concatLists [ hack ];
}
