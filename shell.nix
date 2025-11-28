# Development shell for NixOS configuration
# This provides a standalone development environment without the system-level flake complexity
# Usage: nix-shell or direnv (if enabled)

{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "nixos-config-dev";

  # Development tools and utilities
  nativeBuildInputs = with pkgs; [
    # Version control and collaboration
    git
    git-crypt # Git encryption for sensitive files
    git-lfs # Git Large File Storage
    gh # GitHub CLI tool
    glab # GitLab CLI tool

    # Nix development tools
    nixpkgs-fmt # Nix code formatter
    statix # Nix linter and suggestions
    nix-prefetch-github # Tool for fetching GitHub repositories

    # Development utilities
    pre-commit # Pre-commit hooks framework
    doctl # DigitalOcean CLI (if needed for deployment)

    # System tools
    curl
    wget
    jq # JSON processor
    yq # YAML processor
  ];

  # Environment variables for development
  shellHook = ''
    echo "🔧 NixOS Configuration Development Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Available commands:"
    echo "  nixpkgs-fmt .     - Format Nix files"
    echo "  statix check .    - Lint Nix files"
    echo "  nix flake check   - Validate flake"
    echo "  nix flake update  - Update inputs"
    echo ""
    echo "System commands:"
    echo "  sudo nixos-rebuild switch --flake .#nixos     - Apply system config"
    echo "  home-manager switch --flake .#awfixer@nixos   - Apply user config"
    echo ""

    # Set up pre-commit if config exists and is enabled
    if [ -f .pre-commit-config.yaml ]; then
      echo "📋 Pre-commit hooks are configured (currently disabled)"
      echo "   To re-enable: mv .pre-commit-config.yaml.disabled .pre-commit-config.yaml"
      echo "   Then run: pre-commit install"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '';
}
