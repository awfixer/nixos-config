{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    #nixos-unified.url = "github:srid/nixos-unified";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    determinate.url = "github:Determinatesystems/determinate/";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    any-nix-shell = {
      url = "github:TheMaxMur/any-nix-shell";
    };
  };
  outputs =
    { ... }@inputs:
    let
      systems = [
        "x86_64-linux"
      ];
      nixpkgs = inputs.nixpkgs;
      mkLib = nixpkgs: nixpkgs.lib.extend (final: prev: (import ./lib final));
      lib = mkLib nixpkgs;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = lib.mkHosts [ "nixos" ] "x86_64-linux" inputs;
      checks = lib.genAttrs systems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          nixpkgs-fmt = pkgs.runCommand "check-nixpkgs-fmt" { nativeBuildInputs = [ pkgs.nixpkgs-fmt ]; } ''
            nixpkgs-fmt --check ${./.}
            touch $out
          '';
          statix = pkgs.runCommand "check-statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
            statix check ${./.}
            touch $out
          '';
          pre-commit-check =
            pkgs.runCommand "check-pre-commit" { nativeBuildInputs = [ pkgs.pre-commit ]; }
              ''
                cp -r ${./.} ./repo
                chmod -R +w ./repo
                cd ./repo
                pre-commit run --all-files
                touch $out
              '';
          docs-links = pkgs.runCommand "check-docs-links" { } ''
            if [ -f "${./.}/docs/index.md" ]; then
              echo "Documentation structure validated"
            else
              echo "Missing main documentation index"
              exit 1
            fi
            touch $out
          '';
        }
      );
    };
}
