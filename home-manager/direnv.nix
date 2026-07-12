{ config, lib, pkgs, ... }:

{
  programs.direnv = {
    enable = true;

    # Fast use_nix with persistent cache
    nix-direnv.enable = true;

    # Shell integration — zsh is the login shell
    enableZshIntegration = true;

    # Silence direnv logging to reduce shell noise
    silent = false;

    # direnv.toml: autoload .env files alongside .envrc
    config = {
      global = {
        load_dotenv = true;
      };
    };
  };
}
