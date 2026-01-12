{ ... }:
{
  imports = [
    #./dns.nix
    ./firewall.nix
    #./firejail.nix
    ./mullvad.nix
  ];
}
