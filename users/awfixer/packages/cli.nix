# Command Line Utilities
# Essential CLI tools for productivity and system administration
# CLI tools overview: https://github.com/agarrharr/awesome-cli-apps
{ pkgs, ... }:

let
  # Command-line utilities organized by purpose
  cli = with pkgs; [
    # Development Workflow
    graphite-cli               # Git workflow improvement tool - https://graphite.dev/
    just                      # Command runner and build tool - https://github.com/casey/just
    watchexec                 # Execute commands when files change - https://github.com/watchexec/watchexec
    
    # File and Directory Operations
    eza                       # Modern replacement for ls - https://eza.rocks/
    fd                        # Fast alternative to find - https://github.com/sharkdp/fd
    tree                      # Display directory structure - https://mama.indstate.edu/users/ice/tree/
    ripgrep                   # Fast text search tool - https://github.com/BurntSushi/ripgrep
    sd                        # Intuitive find & replace CLI - https://github.com/chmln/sd
    
    # Data Processing and Manipulation
    jc                        # Convert command output to JSON - https://github.com/kellyjonbrazil/jc
    jq                        # JSON processor - https://jqlang.github.io/jq/
    
    # Media and File Processing
    ffmpeg                    # Complete multimedia framework - https://ffmpeg.org/
    ouch                      # Archive decompression tool - https://github.com/ouch-org/ouch
    
    # Archive and Compression
    unzip                     # Extract ZIP archives
    zip                       # Create ZIP archives
    
    # Network and Download Tools
    wget                      # Download files from web - https://www.gnu.org/software/wget/
    
    # System Integration
    wl-clipboard             # Wayland clipboard utilities - https://github.com/bugaevc/wl-clipboard
  ];
in

{
  # Install all CLI packages to user environment
  home.packages = builtins.concatLists [ cli ];
}
