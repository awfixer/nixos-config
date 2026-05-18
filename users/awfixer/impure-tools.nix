[
  {
    name = "rustup";
    check = ''command -v rustup >/dev/null'';
    install = ''curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'';
    postInstall = ''. "$HOME/.cargo/env"'';
  }
  {
    name = "sdkman";
    check = ''[ -d "$HOME/.sdkman" ]'';
    install = ''curl -s "https://get.sdkman.io" | bash'';
    postInstall = ''source "$HOME/.sdkman/bin/sdkman-init.sh"'';
  }
  {
    name = "nvm";
    check = ''[ -d "$HOME/.nvm" ]'';
    install = ''curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'';
    postInstall = ''export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"'';
  }
]
