{ pkgs, ... }:

let

programming = with pkgs; [
  go
  hugo
  gcc
  cmake
  meson
  nim
  ninja
  zig
  elixir
  gleam
  rustup
  asdf-vm
  sdkmanager
  python314
  pnpm
  bun
  yarn
  nodejs
  llvm
  ruby
  rails-new
  deno
  wasm-tools
  wasm
  wasm-pack
  uv
  poetry
  meld
  nim
  vlang
  clamav
  zig
  kotlin
];

in

{
  home.packages = builtins.concatLists [ programming ];
}
