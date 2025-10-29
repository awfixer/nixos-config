# Tor and Privacy Tools Configuration
# Tools for anonymous networking, privacy, and web servers
# Tor Project: https://www.torproject.org/
# Privacy tools documentation: https://nixos.wiki/wiki/Tor
{ pkgs, ... }:
{
  imports = [
    #./tor.nix     # Tor daemon configuration (currently disabled)
    #./torrc.nix   # Tor configuration file (currently disabled)
  ];
  
  environment = {
    # Privacy and networking tools
    systemPackages = with pkgs; [
      # Tor ecosystem
      tor                    # The Tor anonymity network daemon - https://www.torproject.org/
      arti                   # Rust implementation of Tor - https://gitlab.torproject.org/tpo/core/arti
      tor-browser           # Privacy-focused web browser - https://www.torproject.org/download/
      
      # Web servers (commonly used with Tor hidden services)
      nginx                 # High-performance web server - https://nginx.org/
      caddy                 # Modern web server with automatic HTTPS - https://caddyserver.com/
      
      # VPN tools
      mullvad               # Mullvad VPN client - https://mullvad.net/
      mullvad-closest       # Connect to closest Mullvad server
      mullvad-browser       # Privacy-focused browser by Mullvad - https://mullvad.net/browser
    ];
  };
  
  # Note: Tor daemon configuration is disabled by default
  # To enable Tor as a system service:
  # services.tor.enable = true;
  # Additional Tor configuration can be added in tor.nix and torrc.nix
}
