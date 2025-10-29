# Development Tools and Programming Languages
# Complete development environment for multiple programming languages
# Development tools overview: https://github.com/sindresorhus/awesome#development-environment
{ pkgs, ... }:

let
  # Development packages organized by language and tool category
  dev = with pkgs; [
    # Go Programming Language
    go                        # Go programming language - https://golang.org/
    hugo                      # Static site generator in Go - https://gohugo.io/
    
    # Elixir/Erlang Ecosystem
    elixir                    # Elixir programming language - https://elixir-lang.org/
    erlang                    # Erlang programming language - https://www.erlang.org/
    gleam                     # Type-safe language for Erlang VM - https://gleam.run/
    
    # Rust Programming Language
    rustup                    # Rust toolchain installer - https://rustup.rs/
    
    # Java Development
    sdkmanager               # Android SDK manager
    jdk                      # Java Development Kit
    
    # Ruby Development
    rubyfmt                  # Ruby code formatter - https://github.com/fables-tales/rubyfmt
    ruby                     # Ruby programming language - https://www.ruby-lang.org/
    ruby-lsp                 # Ruby Language Server Protocol - https://github.com/Shopify/ruby-lsp
    rails-new                # Ruby on Rails application generator
    gem                      # Ruby package manager
    
    # C/C++ Development
    llvm                     # LLVM compiler infrastructure - https://llvm.org/
    llvmPackages.llvm        # LLVM core libraries
    llvmPackages.llvm-manpages # LLVM documentation
    clang                    # C/C++/Objective-C compiler - https://clang.llvm.org/
    clang-tools              # Clang development tools
    gnumake                  # GNU Make build tool - https://www.gnu.org/software/make/
    pkg-config               # Package configuration tool
    
    # Development Environment Tools
    devbox                   # Isolated development environments - https://www.jetpack.io/devbox/
    zed-editor              # High-performance code editor - https://zed.dev/
    ghostty                 # GPU-accelerated terminal emulator - https://ghostty.org/
    
    # JavaScript/TypeScript Development
    pnpm                    # Fast, disk space efficient package manager - https://pnpm.io/
    nodejs                  # JavaScript runtime - https://nodejs.org/
    yarn                    # JavaScript package manager - https://yarnpkg.com/
    bun                     # Fast JavaScript runtime and toolkit - https://bun.sh/
    deno                    # Secure JavaScript/TypeScript runtime - https://deno.land/
    
    # Python Development
    python314               # Python 3.14 programming language - https://www.python.org/
    uv                      # Fast Python package installer - https://github.com/astral-sh/uv
  ];
in

{
  # Install all development packages to user environment
  home.packages = builtins.concatLists [ dev ];
}
