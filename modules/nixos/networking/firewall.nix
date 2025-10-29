# Firewall Configuration - Network Security
# Configure iptables-based firewall rules for network access control
# NixOS firewall: https://nixos.org/manual/nixos/stable/#sec-firewall
# Firewall options: https://search.nixos.org/options?query=networking.firewall
{ ... }:
{
  # Enable ICMP ping responses
  networking.firewall.allowPing = true;
  
  networking.firewall = {
    enable = true;                    # Enable the firewall
    
    # Allowed TCP ports for incoming connections
    allowedTCPPorts = [
      # Development and web servers
      3000                           # Common development server port
      1234                           # Development/testing port
      4321                           # Development/testing port  
      8080                           # Alternative HTTP port
      
      # GSConnect/KDE Connect port range (1714-1764)
      # Used for device synchronization and communication
      # GSConnect: https://github.com/GSConnect/gnome-shell-extension-gsconnect
      1714 1715 1716 1717 1718 1719 1720 1721 1722 1723
      1724 1725 1726 1727 1728 1729 1730 1731 1732 1733
      1734 1735 1736 1737 1738 1739 1740 1741 1742 1743
      1744 1745 1746 1747 1748 1749 1750 1751 1752 1753
      1754 1755 1756 1757 1758 1759 1760 1761 1762 1763
      1764
    ];
    
    # Allowed UDP ports for incoming connections
    allowedUDPPorts = [
      # Development and web servers
      3000                           # Common development server port
      1234                           # Development/testing port
      4321                           # Development/testing port
      8080                           # Alternative HTTP port
      
      # GSConnect/KDE Connect port range (1714-1764)
      # UDP is used for device discovery and some communication
      1714 1715 1716 1717 1718 1719 1720 1721 1722 1723
      1724 1725 1726 1727 1728 1729 1730 1731 1732 1733
      1734 1735 1736 1737 1738 1739 1740 1741 1742 1743
      1744 1745 1746 1747 1748 1749 1750 1751 1752 1753
      1754 1755 1756 1757 1758 1759 1760 1761 1762 1763
      1764
    ];
    
    # Additional firewall configuration options:
    # allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];  # Alternative range syntax
    # allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    # interfaces = { ... };                                     # Interface-specific rules
    # extraCommands = "...";                                   # Custom iptables commands
    # logRefusedConnections = false;                            # Disable connection logging
  };
}
