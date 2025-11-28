{ pkgs, ... }:
let
  settings = builtins.concatMap.json;
  inherit = {file.settings.json};

{
  imports = [
    ./super.nix
    ./settings.json
  ];
}
