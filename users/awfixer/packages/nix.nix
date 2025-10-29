# Nix Ecosystem Tools
# Tools for Nix development, debugging, and ecosystem management
# Nix ecosystem overview: https://github.com/nix-community/awesome-nix
{ pkgs, ... }:

let
  # Nix development and management tools
  nix = with pkgs; [
    # Language Servers and Development
    nil                      # Nix language server - https://github.com/oxalica/nil
    nixd                     # Nix language server with more features - https://github.com/nix-community/nixd
    nixpkgs-fmt             # Nix code formatter - https://github.com/nix-community/nixpkgs-fmt
    
    # System Information and Debugging
    nix-info                # System information for Nix - https://github.com/NixOS/nix/blob/master/scripts/nix-info.sh
    nix-tree                # Visualize Nix dependency tree - https://github.com/utdemir/nix-tree
    nix-health              # Check Nix installation health - https://github.com/juspay/nix-health
    
    # Documentation and Web Tools
    nix-doc                 # Nix documentation generator - https://github.com/lf-/nix-doc
    nix-web                 # Web interface for Nix - https://github.com/hackworthltd/nix-web
    
    # Deployment and Management
    nix-deploy              # Deploy Nix configurations - https://github.com/awakesecurity/nix-deploy
    omnix                   # Unified interface for Nix projects - https://github.com/juspay/omnix
    
    # Shell Integration
    nix-zsh-completions     # Zsh completions for Nix - https://github.com/nix-community/nix-zsh-completions
  ];
in

{
  # Install all Nix ecosystem packages to user environment
  home.packages = builtins.concatLists [ nix ];
}
