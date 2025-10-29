# Security and Penetration Testing Tools
# IMPORTANT: These tools are for defensive security purposes only
# Use responsibly and only on systems you own or have explicit permission to test
# Security tools overview: https://github.com/enaqx/awesome-pentest
{pkgs, ... }:

let
  # Security and penetration testing tools organized by category
  hack = with pkgs; [
    # Repository and Code Analysis
    ghorg                     # Clone all repos from GitHub org - https://github.com/gabrie30/ghorg
    ghost                     # Remote debugger for Android apps - https://github.com/entysec/ghost
    
    # Network Analysis and Monitoring
    wireshark-cli            # Network protocol analyzer (CLI) - https://www.wireshark.org/
    netcat                   # Network utility for TCP/UDP connections - https://nc110.sourceforge.io/
    angryipscanner          # Fast IP scanner - https://angryip.org/
    nmap                    # Network discovery and security auditing - https://nmap.org/
    
    # Malware Analysis
    yara                    # Pattern matching engine for malware research - https://virustotal.github.io/yara/
    yaralyzer              # YARA rule analysis tool - https://github.com/michelcrypt4d4mus/yaralyzer
    
    # Web Application Security Testing
    burpsuite              # Web vulnerability scanner - https://portswigger.net/burp
    
    # Password Security Testing
    hydra                  # Parallelized login cracker - https://github.com/vanhauser-thc/thc-hydra
    hashcat                # Advanced password recovery - https://hashcat.net/hashcat/
    hashcat-utils          # Utilities for hashcat
    
    # Penetration Testing Framework
    metasploit             # Penetration testing framework - https://www.metasploit.com/
  ];
in

{
  # Install all security testing packages to user environment
  # Note: Use these tools responsibly and ethically
  home.packages = builtins.concatLists [ hack ];
}
