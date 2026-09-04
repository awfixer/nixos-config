{
  config,
  lib,
  pkgs,
  ...
}:

# System Playwright + Prisma tooling for NixOS.
# npm/bun local installs honor these env vars and skip downloading broken
# prebuilt engines/browsers (see wiki.nixos.org/wiki/Playwright and the
# prisma-engines setup-hook in nixpkgs).
let
  playwrightBrowsers = pkgs.playwright-driver.browsers;
  localPrismaHome = "/home/awfixer/.local/prisma";
  localSchemaEngine = "${localPrismaHome}/bin/schema-engine";
  localPrismaFmt = "${localPrismaHome}/bin/prisma-fmt";
in
{
  environment.systemPackages = with pkgs; [
    playwright-test # `playwright` CLI, default BROWSERS_PATH
    prisma # `prisma` CLI, wraps schema-engine (7.x fallback)
    prisma-engines # engines + setup-hook for nix shells (7.x fallback)
  ];

  environment.sessionVariables = {
    # Playwright (npm / bun / @playwright/test)
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";

    # Prisma 8 engines built on this machine (~/.local/prisma). The 7.x
    # nixpkgs engines remain installed as a fallback for `nix develop`.
    PRISMA_HOME = localPrismaHome;
    PRISMA_SCHEMA_ENGINE_BINARY = localSchemaEngine;
    PRISMA_FMT_BINARY = localPrismaFmt;
    PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING = "1";
  };

  # Ensure login shells and non-interactive systemd user sessions also see them.
  environment.variables = {
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    PRISMA_HOME = localPrismaHome;
    PRISMA_SCHEMA_ENGINE_BINARY = localSchemaEngine;
    PRISMA_FMT_BINARY = localPrismaFmt;
    PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING = "1";
  };
}
