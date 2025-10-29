---
title: Resources & Links
description: Useful resources for learning and working with NixOS
---

# Resources & Links

A curated collection of resources for learning NixOS, Nix language, and related technologies.

## Official Documentation

### NixOS
- **[NixOS Manual](https://nixos.org/manual/nixos/stable/)** - Complete NixOS system manual
- **[Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)** - Package collection documentation
- **[Nix Reference Manual](https://nixos.org/manual/nix/stable/)** - Nix package manager documentation
- **[NixOS Options Search](https://search.nixos.org/options)** - Search all NixOS configuration options
- **[Package Search](https://search.nixos.org/packages)** - Search available packages

### Home Manager
- **[Home Manager Manual](https://nix-community.github.io/home-manager/)** - User environment management
- **[Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)** - Complete options reference
- **[Home Manager Examples](https://github.com/nix-community/home-manager/tree/master/modules)** - Configuration examples

### Nix Flakes
- **[Flakes Wiki](https://nixos.wiki/wiki/Flakes)** - Comprehensive flakes guide
- **[Flakes Reference](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)** - Official flakes documentation
- **[Flake Utils](https://github.com/numtide/flake-utils)** - Utility functions for flakes

## Learning Resources

### Beginner Guides
- **[Zero to Nix](https://zero-to-nix.com/)** - Modern introduction to Nix
- **[Nix Pills](https://nixos.org/guides/nix-pills/)** - Deep dive tutorial series
- **[NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)** - Comprehensive modern guide
- **[Determinate Systems Guide](https://determinate.systems/posts/nix-run/)** - Practical Nix usage

### Video Content
- **[NixOS Tutorials by Vimjoyer](https://www.youtube.com/c/vimjoyer)** - Video tutorials and tips
- **[Burke Libbey's Nix Content](https://www.youtube.com/@burkelibbey)** - Advanced Nix concepts
- **[NixCon Talks](https://www.youtube.com/c/NixCon)** - Conference presentations

### Interactive Learning
- **[Nix Tour](https://nixcloud.io/tour/)** - Interactive Nix language tutorial
- **[Learn Nix the Fun Way](https://ianthehenry.com/posts/how-to-learn-nix/)** - Practical learning approach

## Community

### Forums & Discussion
- **[NixOS Discourse](https://discourse.nixos.org/)** - Official community forum
- **[r/NixOS](https://www.reddit.com/r/NixOS/)** - Reddit community
- **[Matrix Chat](https://matrix.to/#/#nixos:nixos.org)** - Real-time chat
- **[IRC](https://nixos.org/community/index.html#chat)** - Traditional IRC channels

### Social Media
- **[NixOS Twitter](https://twitter.com/nixos_org)** - Official updates
- **[NixOS Mastodon](https://chaos.social/@nixos_org)** - Decentralized social media

## Development Tools

### Language Support
- **[nix-lsp](https://github.com/nix-community/nixd)** - Language server protocol
- **[nil](https://github.com/oxalica/nil)** - Alternative LSP implementation
- **[nix-tree](https://github.com/utdemir/nix-tree)** - Dependency tree visualization
- **[nix-diff](https://github.com/Gabriel439/nix-diff)** - Compare Nix expressions

### Formatters & Linters
- **[nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)** - Official formatter
- **[alejandra](https://github.com/kamadorueda/alejandra)** - Opinionated formatter
- **[statix](https://github.com/nerdypepper/statix)** - Linter for Nix
- **[deadnix](https://github.com/astro/deadnix)** - Dead code detection

### Development Environments
- **[devenv](https://devenv.sh/)** - Fast development environments
- **[devbox](https://www.jetify.com/devbox/)** - Isolated development shells
- **[nix-shell](https://nixos.org/manual/nix/stable/command-ref/nix-shell.html)** - Built-in development shells

## Configuration Examples

### Public Configurations
- **[NixOS Config Collection](https://github.com/nix-community/awesome-nix#nixos-configuration-examples)** - Curated examples
- **[Misterio77's Config](https://github.com/Misterio77/nix-config)** - Well-documented setup
- **[hlissner's dotfiles](https://github.com/hlissner/dotfiles)** - Comprehensive configuration
- **[berberman's flakes](https://github.com/berberman/flakes)** - Modern flake examples

### Specialized Setups
- **[Gaming on NixOS](https://github.com/fufexan/nix-gaming)** - Gaming-focused configuration
- **[Server Configurations](https://github.com/numtide/nixos-anywhere)** - Server deployment tools
- **[Mobile NixOS](https://mobile.nixos.org/)** - NixOS on mobile devices

## Package Development

### Creating Packages
- **[Packaging Guide](https://nixos.org/manual/nixpkgs/stable/#chap-quick-start)** - How to package software
- **[NUR](https://github.com/nix-community/NUR)** - Nix User Repository
- **[nixpkgs Contributing](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)** - Contribution guidelines

### Package Utilities
- **[nix-prefetch](https://github.com/msteen/nix-prefetch)** - Fetch package sources
- **[nix-update](https://github.com/Mic92/nix-update)** - Automated package updates
- **[nvfetcher](https://github.com/berberman/nvfetcher)** - Source fetching automation

## Deployment & CI/CD

### Deployment Tools
- **[deploy-rs](https://github.com/serokell/deploy-rs)** - Multi-host deployment
- **[colmena](https://github.com/zhaofengli/colmena)** - NixOS deployment tool
- **[morph](https://github.com/DBCDK/morph)** - Deployment utility
- **[nixos-anywhere](https://github.com/numtide/nixos-anywhere)** - Remote installation

### CI/CD
- **[GitHub Actions for Nix](https://github.com/cachix/install-nix-action)** - Nix in GitHub workflows
- **[Cachix](https://cachix.org/)** - Binary cache hosting
- **[Hydra](https://nixos.org/hydra/)** - Nix-based CI system

## Specialized Topics

### Security
- **[SOPS-Nix](https://github.com/Mic92/sops-nix)** - Secrets management
- **[agenix](https://github.com/ryantm/agenix)** - Age-based secrets
- **[Security Hardening](https://nixos.wiki/wiki/Security)** - Security best practices

### Container & VM
- **[NixOS Containers](https://nixos.wiki/wiki/NixOS_Containers)** - System containers
- **[MicroVM.nix](https://github.com/astro/microvm.nix)** - Lightweight VMs
- **[Docker Integration](https://nixos.wiki/wiki/Docker)** - Using Docker with NixOS

### Cross-Platform
- **[nix-darwin](https://github.com/LnL7/nix-darwin)** - NixOS-like system for macOS
- **[WSL Support](https://github.com/nix-community/NixOS-WSL)** - NixOS on Windows Subsystem for Linux

## Troubleshooting Resources

### Common Issues
- **[NixOS Wiki Troubleshooting](https://nixos.wiki/wiki/Troubleshooting)** - Common problems and solutions
- **[NixOS FAQ](https://nixos.org/manual/nixos/stable/index.html#sec-faq)** - Frequently asked questions
- **[Common Pitfalls](https://nixos.wiki/wiki/FAQ)** - Things to avoid

### Debug Tools
- **[nix-tree](https://github.com/utdemir/nix-tree)** - Dependency analysis
- **[nix-du](https://github.com/symphorien/nix-du)** - Store usage analysis
- **[nix-index](https://github.com/bennofs/nix-index)** - File location database

## Books & Long-form Content

### Books
- **[NixOS in Production](https://leanpub.com/nixos-in-production)** - Enterprise deployment guide
- **[Functional Package Management](https://edolstra.github.io/pubs/phd-thesis.pdf)** - Eelco Dolstra's PhD thesis

### Blog Posts & Articles
- **[Determinate Systems Blog](https://determinate.systems/posts/)** - Modern Nix practices
- **[Tweag Blog Nix Posts](https://www.tweag.io/blog/tags/nix/)** - Advanced concepts
- **[Xe Iaso's Nix Posts](https://xeiaso.net/blog/series/nix)** - Practical tutorials

## Package Ecosystems

### Language-Specific
- **[Python](https://nixos.org/manual/nixpkgs/stable/#python)** - Python packaging in Nix
- **[Rust](https://nixos.org/manual/nixpkgs/stable/#rust)** - Rust/Cargo integration
- **[Node.js](https://nixos.org/manual/nixpkgs/stable/#node.js)** - Node.js and npm packages
- **[Haskell](https://nixos.org/manual/nixpkgs/stable/#haskell)** - Haskell ecosystem

### Overlays & Extensions
- **[NUR Browser](https://nur.nix-community.org/)** - Browse user repositories
- **[Awesome Nix](https://github.com/nix-community/awesome-nix)** - Curated resources
- **[Nixpkgs Overlays](https://nixos.wiki/wiki/Overlays)** - Package modification guide

---

::: tip Contributing
Know of a great resource that should be listed here? Feel free to submit a pull request or open an issue on GitHub!
:::

::: info Staying Updated
- Follow [@nixos_org](https://twitter.com/nixos_org) for announcements
- Subscribe to [NixOS Weekly](https://weekly.nixos.org/) newsletter
- Join community discussions on [Discourse](https://discourse.nixos.org/)
:::