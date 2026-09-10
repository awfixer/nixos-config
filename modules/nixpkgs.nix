{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      helium-browser = final.callPackage ../packages/helium { };
      helium-devtools = final.callPackage ../packages/helium-devtools { };
      buzz = final.callPackage ../packages/buzz { };
      gloomberb = final.callPackage ../packages/gloomberb { };
      openwork = final.callPackage ../packages/openwork { };
      kraken-desktop = final.callPackage ../packages/kraken { };
      vela-cli = final.callPackage ../packages/vela { };
      t3-code = final.callPackage ../packages/t3-code { };
      grok-bot = final.callPackage ../packages/grok-bot { };
      macbook-thermal = final.callPackage ../packages/macbook-thermal { };
      brave-search = final.callPackage ../packages/brave-search { };
      #orion-browser = final.callPackage ../packages/orion { };
      #zen-browser = final.callPackage ../packages/zen-browser { };
      #windscribe = final.callPackage ../packages/windscribe { };
    })
  ];

  # 8 GiB machine: never parallel-build (multiple rustc/llvm jobs → instant OOM).
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = 1;
    cores = 2;
    # Leave free space / breathing room for the session during store GC pressure.
    min-free = 512 * 1024 * 1024; # 512 MiB
    max-free = 3 * 1024 * 1024 * 1024; # 3 GiB target after GC
  };

  nixpkgs.config.allowUnfree = true;
}
